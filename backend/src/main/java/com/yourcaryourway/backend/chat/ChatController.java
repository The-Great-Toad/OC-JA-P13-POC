package com.yourcaryourway.backend.chat;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.stereotype.Controller;

@Controller
public class ChatController {

    // Intercepte les requêtes WebSocket sur la destination "/app/chat.sendMessage"
    // et dispatche la réponse sur le topic "/topic/public"
    @MessageMapping("/chat.sendMessage")
    @SendTo("/topic/public")
    public ChatMessage sendMessage(@Payload ChatMessage chatMessage) {
        return chatMessage;
    }

    // Intercepte l'arrivée d'un nouvel utilisateur (Notification JOIN)
    @MessageMapping("/chat.addUser")
    @SendTo("/topic/public")
    public ChatMessage addUser(@Payload ChatMessage chatMessage, SimpMessageHeaderAccessor headerAccessor) {
        // Ajoute le username dans la session WebSocket locale
        headerAccessor.getSessionAttributes().put("username", chatMessage.sender());
        return chatMessage;
    }
}
