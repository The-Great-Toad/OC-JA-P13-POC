package com.yourcaryourway.backend.chat;

/**
 * Modèle immuable représentant un message sur le Chat.
 */
public record ChatMessage(MessageType type, String content, String sender) {

    public enum MessageType {
        CHAT,
        JOIN,
        LEAVE
    }
}
