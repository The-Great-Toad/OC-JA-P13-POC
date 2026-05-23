import { Injectable, signal, DestroyRef, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { RxStomp } from '@stomp/rx-stomp';
import { ChatMessage, MessageType } from '../models/chat-message';

@Injectable({
  providedIn: 'root'
})
export class ChatService {
  private rxStomp = new RxStomp();
  private destroyRef = inject(DestroyRef);
  
  public messages = signal<ChatMessage[]>([]);
  public isConnected = signal<boolean>(false);
  public currentUser = signal<string | null>(null);

  constructor() {
    this.destroyRef.onDestroy(() => {
      this.disconnect();
    });
  }

  connect(username: string) {
    this.rxStomp.configure({
      brokerURL: 'ws://localhost:8080/ws',
      debug: (msg: string) => {
        console.log(new Date(), msg); // A supprimer en production
      }
    });

    this.rxStomp.activate();
    this.isConnected.set(true);
    this.currentUser.set(username);

    this.rxStomp.watch('/topic/public').pipe(
      takeUntilDestroyed(this.destroyRef)
    ).subscribe((message) => {
      const chatMessage: ChatMessage = JSON.parse(message.body);
      this.messages.update((msgs) => [...msgs, chatMessage]);
    });

    this.rxStomp.publish({
      destination: '/app/chat.addUser',
      body: JSON.stringify({ sender: username, type: MessageType.JOIN })
    });
  }

  sendMessage(content: string) {
    const user = this.currentUser();
    if (user && content.trim() !== '') {
      const chatMessage: ChatMessage = {
        sender: user,
        content: content.trim(),
        type: MessageType.CHAT
      };
      
      this.rxStomp.publish({
        destination: '/app/chat.sendMessage',
        body: JSON.stringify(chatMessage)
      });
    }
  }

  disconnect() {
    if (this.isConnected()) {
      this.rxStomp.publish({
        destination: '/app/chat.addUser',
        body: JSON.stringify({ sender: this.currentUser(), type: MessageType.LEAVE })
      });
      this.rxStomp.deactivate();
    }
    
    this.isConnected.set(false);
    this.currentUser.set(null);
    this.messages.set([]);
  }
}
