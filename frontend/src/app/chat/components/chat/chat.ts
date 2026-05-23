import { Component, inject, signal } from '@angular/core';
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

  joinChat() {
    if (this.username().trim()) {
      this.chatService.connect(this.username());
    }
  }

  sendMessage() {
    if (this.messageContent().trim()) {
      this.chatService.sendMessage(this.messageContent());
      this.messageContent.set(''); // Clear input
    }
  }

  leaveChat() {
    this.chatService.disconnect();
    this.username.set('');
  }
}
