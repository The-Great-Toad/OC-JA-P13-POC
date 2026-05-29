# PoC : Chat en Temps Réel (Your Car Your Way)

Ce dossier contient la Preuve de Concept (PoC) du projet OpenClassrooms P13.
Il démontre la faisabilité technique du point le plus risqué de l'architecture : **la communication synchrone en temps réel via WebSockets entre un client et l'équipe de support**.

## Structure globale

- `/backend` : API REST & Broker WebSocket (Spring Boot / Java 21)
- `/frontend` : Client Web SPA (Angular 21 / TypeScript)

---

## Comment lancer le PoC ?

### 1. Backend (Spring Boot)

Ouvrez un terminal dans le dossier `backend/` et lancez l'application avec le wrapper Maven :

```bash
cd backend
./mvnw spring-boot:run
```

> Le serveur démarrera sur **`http://localhost:8080`**.

### 2. Frontend (Angular)

Ouvrez un deuxième terminal dans le dossier `frontend/`, installez les dépendances et lancez le serveur de développement :

```bash
cd frontend
npm install
npm start
```

> L'application client démarrera sur **`http://localhost:4200`**.

---

## Scénario de test (Démonstration)

1. Ouvrez `http://localhost:4200` dans **deux onglets** ou **deux navigateurs** différents.
2. Dans le premier onglet, connectez-vous avec le rôle **CLIENT** (ex: "Alice").
3. Dans le second onglet, connectez-vous avec le rôle **SUPPORT** (ex: "Bob").
4. Envoyez un message depuis le client : il apparaîtra **instantanément** côté support !
5. Vous pouvez également tester la clôture de la conversation par le support ou l'apparition du badge de notification quand la modale de chat est fermée.
