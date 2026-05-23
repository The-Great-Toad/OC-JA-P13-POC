export enum MessageType {
  CHAT = 'CHAT',
  JOIN = 'JOIN',
  LEAVE = 'LEAVE'
}

export interface ChatMessage {
  type: MessageType;
  content: string;
  sender: string;
}
