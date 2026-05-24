import {
  Component,
  inject,
  signal,
  ViewChild,
  ElementRef,
  effect,
  afterNextRender,
  Injector,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ChatService } from '../../services/chat';
import { MessageType, RoleType } from '../../models/chat-message';

@Component({
  selector: 'app-chat',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './chat.html',
  styleUrl: './chat.scss',
})
export class Chat {
  public chatService = inject(ChatService);
  private injector = inject(Injector);

  public username = signal<string>('');
  public selectedRole = signal<RoleType>('CLIENT');
  public messageContent = signal<string>('');
  public isOpen = signal<boolean>(false);
  public unreadCount = signal<number>(0);
  public isClosed = signal<boolean>(false);

  @ViewChild('scrollMe') private myScrollContainer!: ElementRef;

  private previousMessageCount = 0;

  constructor() {
    effect(() => {
      const messages = this.chatService.messages();
      if (messages.length > this.previousMessageCount) {
        // Détection de la clôture
        const lastMessage = messages[messages.length - 1];
        if (lastMessage.type === MessageType.CLOSE) {
          this.isClosed.set(true);
        }

        if (!this.isOpen()) {
          const newMessagesCount = messages
            .slice(this.previousMessageCount)
            .filter((m) => m.type === 'CHAT').length;
          if (newMessagesCount > 0) {
            this.unreadCount.update((c) => c + newMessagesCount);
          }
        } else {
          this.scrollToBottom();
        }
      }
      this.previousMessageCount = messages.length;
    });
  }

  toggleChat() {
    this.isOpen.update((v) => !v);
    if (this.isOpen()) {
      this.unreadCount.set(0);
      this.scrollToBottom();
    }
  }

  private scrollToBottom(): void {
    afterNextRender(
      () => {
        if (this.myScrollContainer) {
          this.myScrollContainer.nativeElement.scrollTop =
            this.myScrollContainer.nativeElement.scrollHeight;
        }
      },
      { injector: this.injector },
    );
  }

  joinChat() {
    if (this.username().trim()) {
      this.isClosed.set(false);
      this.chatService.connect(this.username(), this.selectedRole());
    }
  }

  sendMessage() {
    if (this.messageContent().trim()) {
      this.chatService.sendMessage(this.messageContent());
      this.messageContent.set('');
    }
  }

  leaveChat() {
    if (this.selectedRole() === 'CLIENT') {
      const confirmLeave = window.confirm(
        'Souhaitez-vous vraiment quitter le chat ? Votre historique de conversation sera perdu.',
      );
      if (!confirmLeave) {
        return;
      }
    }
    this.chatService.disconnect();
    this.username.set('');
    this.isOpen.set(false);
  }

  cloturerChat() {
    if (window.confirm('Confirmez-vous la clôture de cette conversation ?')) {
      this.chatService.closeConversation();
      setTimeout(() => {
        this.leaveChat();
      }, 500);
    }
  }
}
