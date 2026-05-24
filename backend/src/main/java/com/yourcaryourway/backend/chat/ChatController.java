package com.yourcaryourway.backend.chat;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

@RestController
@RequestMapping("/chat")
public class ChatController {

    // Historique du chat du support pour la durée du POC
    private final List<ChatMessage> history = new CopyOnWriteArrayList<>();

    // Récupérer l'historique lors d'une nouvelle connexion
    @GetMapping("/history")
    public List<ChatMessage> getHistory() {
        return history;
    }

    // Intercepte les requêtes WebSocket sur la destination "/app/chat.sendMessage"
    // et dispatche la réponse sur le topic "/topic/public"
    @MessageMapping("/chat.sendMessage")
    @SendTo("/topic/public")
    public ChatMessage sendMessage(@Payload ChatMessage chatMessage) {
        history.add(chatMessage);
        return chatMessage;
    }

    // Intercepte l'arrivée d'un nouvel utilisateur (Notification JOIN)
    @MessageMapping("/chat.addUser")
    @SendTo("/topic/public")
    public ChatMessage addUser(@Payload ChatMessage chatMessage, SimpMessageHeaderAccessor headerAccessor) {
        // Ajoute le username dans la session WebSocket locale
        Map<String, Object> sessionAttributes = headerAccessor.getSessionAttributes();
        if (sessionAttributes != null) {
            sessionAttributes.put("username", chatMessage.sender());
        }
        history.add(chatMessage);
        return chatMessage;
    }
}
