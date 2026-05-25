/**
 * Enum représentant les types de messages dans le chat, incluant les types de message de chat (CHAT), d'entrée dans la conversation (JOIN), de sortie de la conversation (LEAVE) et de clôture de la conversation (CLOSE).
 * - `CHAT`: Représente un message de chat normal envoyé par un utilisateur.
 * - `JOIN`: Indique qu'un utilisateur a rejoint la conversation.
 * - `LEAVE`: Indique qu'un utilisateur a quitté la conversation.
 * - `CLOSE`: Indique que la conversation a été clôturée, généralement par un agent de support.
 */
export enum MessageType {
  CHAT = 'CHAT',
  JOIN = 'JOIN',
  LEAVE = 'LEAVE',
  CLOSE = 'CLOSE',
}

/**
 * Type représentant les rôles possibles dans le chat, soit 'CLIENT' pour les clients, soit 'SUPPORT' pour les agents de support.
 * - 'CLIENT': Représente un utilisateur client qui initie la conversation.
 * - 'SUPPORT': Représente un agent de support qui répond aux clients.
 */
export type RoleType = 'CLIENT' | 'SUPPORT';

/**
 * Interface représentant un message de chat, incluant le type de message (CHAT, JOIN, LEAVE, CLOSE), le contenu du message, l'expéditeur et éventuellement le rôle de l'expéditeur (CLIENT ou SUPPORT).
 * - `type`: Indique le type de message (CHAT, JOIN, LEAVE, CLOSE).
 * - `content`: Contenu du message (texte du chat).
 * - `sender`: Nom de l'expéditeur du message.
 * - `role` (optionnel): Rôle de l'expéditeur, soit 'CLIENT' soit 'SUPPORT'.
 */
export interface ChatMessage {
  type: MessageType;
  content: string;
  sender: string;
  role?: RoleType;
}
