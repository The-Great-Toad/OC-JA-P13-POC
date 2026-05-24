package com.yourcaryourway.backend.chat;

/**
 * Modèle immuable représentant un message sur le Chat.
 */
public record ChatMessage(MessageType type, String content, String sender, String role) {

    public enum MessageType {
        CHAT,
        JOIN,
        LEAVE,
        CLOSE
    }
}
