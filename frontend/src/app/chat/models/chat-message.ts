export enum MessageType {
  CHAT = 'CHAT',
  JOIN = 'JOIN',
  LEAVE = 'LEAVE',
}

export type RoleType = 'CLIENT' | 'SUPPORT';

export interface ChatMessage {
  type: MessageType;
  content: string;
  sender: string;
  role?: RoleType;
}
