import { Injectable, signal, DestroyRef, inject, isDevMode } from '@angular/core';
import { environment } from '../../../environments/environment';
import { HttpClient } from '@angular/common/http';
import { RxStomp } from '@stomp/rx-stomp';
import { Subscription } from 'rxjs';
import { ChatMessage, MessageType, RoleType } from '../models/chat-message';
@Injectable({ providedIn: 'root' })
export class ChatService {
  private rxStomp = new RxStomp();
  private destroyRef = inject(DestroyRef);
  private http = inject(HttpClient);
  private topicSubscription?: Subscription;

  public messages = signal<ChatMessage[]>([]);
  public isConnected = signal<boolean>(false);
  public currentUser = signal<string | null>(null);
  public currentRole = signal<RoleType>('CLIENT');
  constructor() {
    this.destroyRef.onDestroy(() => {
      this.disconnect();
    });
  }
  connect(username: string, role: RoleType) {
    if (role === 'SUPPORT') {
      this.http.get<ChatMessage[]>(`${environment.apiUrl}/chat/history`).subscribe({
        next: (history) => {
          this.messages.set(history);
        },
        error: (err) => console.error("Impossible de récupérer l'historique", err),
      });
    } else {
      this.messages.set([]);
    }

    this.rxStomp.configure({
      brokerURL: environment.wsUrl,
      debug: isDevMode() ? (msg: string) => console.log(new Date(), msg) : undefined,
    });
    this.rxStomp.activate();
    this.isConnected.set(true);
    this.currentUser.set(username);
    this.currentRole.set(role);

    // On s'assure de nettoyer une éventuelle précédente souscription
    if (this.topicSubscription) {
      this.topicSubscription.unsubscribe();
    }

    this.topicSubscription = this.rxStomp.watch('/topic/public').subscribe((message) => {
      const chatMessage: ChatMessage = JSON.parse(message.body);
      this.messages.update((msgs) => [...msgs, chatMessage]);
    });

    this.rxStomp.publish({
      destination: '/app/chat.addUser',
      body: JSON.stringify({ sender: username, type: MessageType.JOIN, role: role }),
    });
  }
  sendMessage(content: string) {
    const user = this.currentUser();
    const role = this.currentRole();
    if (user && content.trim() !== '') {
      const chatMessage: ChatMessage = {
        sender: user,
        content: content.trim(),
        type: MessageType.CHAT,
        role: role,
      };
      this.rxStomp.publish({
        destination: '/app/chat.sendMessage',
        body: JSON.stringify(chatMessage),
      });
    }
  }
  closeConversation() {
    const user = this.currentUser();
    const role = this.currentRole();
    if (user) {
      this.rxStomp.publish({
        destination: '/app/chat.sendMessage',
        body: JSON.stringify({ sender: user, type: MessageType.CLOSE, role: role, content: '' }),
      });
    }
  }

  disconnect() {
    if (this.isConnected()) {
      this.rxStomp.publish({
        destination: '/app/chat.addUser',
        body: JSON.stringify({
          sender: this.currentUser(),
          type: MessageType.LEAVE,
          role: this.currentRole(),
        }),
      });
      if (this.topicSubscription) {
        this.topicSubscription.unsubscribe();
        this.topicSubscription = undefined;
      }
      this.rxStomp.deactivate();
      this.isConnected.set(false);
      this.currentUser.set(null);
      this.messages.set([]);
    }
  }
}
