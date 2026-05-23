import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Chat } from './chat/components/chat/chat';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, Chat],
  template: '<app-chat></app-chat>'
})
export class AppComponent {
  title = 'frontend';
}
