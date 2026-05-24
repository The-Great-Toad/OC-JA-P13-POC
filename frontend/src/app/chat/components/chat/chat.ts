import { Component, inject, signal, ViewChild, ElementRef, effect } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ChatService } from '../../services/chat';

@Component({
  selector: 'app-chat',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './chat.html',
  styleUrl: './chat.scss',
})
export class Chat {
  public chatService = inject(ChatService);

  public username = signal<string>('');
  public messageContent = signal<string>('');
  public isOpen = signal<boolean>(false);
  public unreadCount = signal<number>(0);

  @ViewChild('scrollMe') private myScrollContainer!: ElementRef;

  private previousMessageCount = 0;

  constructor() {
    effect(() => {
      const messages = this.chatService.messages();
      if (messages.length > this.previousMessageCount) {
        if (!this.isOpen()) {
          this.unreadCount.update((c) => c + (messages.length - this.previousMessageCount));
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
    setTimeout(() => {
      if (this.myScrollContainer) {
        this.myScrollContainer.nativeElement.scrollTop =
          this.myScrollContainer.nativeElement.scrollHeight;
      }
    }, 50);
  }

  joinChat() {
    if (this.username().trim()) {
      this.chatService.connect(this.username());
    }
  }

  sendMessage() {
    if (this.messageContent().trim()) {
      this.chatService.sendMessage(this.messageContent());
      this.messageContent.set('');
    }
  }

  leaveChat() {
    this.chatService.disconnect();
    this.username.set('');
    this.isOpen.set(false);
  }
}
