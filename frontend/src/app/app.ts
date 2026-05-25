import { Component } from '@angular/core';
import { Chat } from './chat/components/chat/chat';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [Chat],
  templateUrl: './app.html',
  styleUrls: ['./app.scss'],
})
export class AppComponent {
  title = 'frontend';
}
