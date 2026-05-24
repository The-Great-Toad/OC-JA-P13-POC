import { Component } from '@angular/core';
import { Chat } from './chat/components/chat/chat';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [Chat],
  template: '<app-chat></app-chat>',
})
export class AppComponent {
  title = 'frontend';
}
