-- Script d'initialisation de la base de données PostgreSQL
-- Projet : Your Car Your Way

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- TABLES DE RÉFÉRENTIELS (Données Maîtres)
-- ==========================================

-- Table des Pays
CREATE TABLE country (
    code VARCHAR(2) PRIMARY KEY, -- ISO 3166-1 alpha-2 (ex: FR, US, UK)
    name VARCHAR(100) NOT NULL
);

-- Table des Devises
CREATE TABLE currency (
    code VARCHAR(3) PRIMARY KEY, -- ISO 4217 (ex: EUR, USD)
    symbol VARCHAR(5) NOT NULL
);

-- Table des Langues/Locales
CREATE TABLE language (
    code VARCHAR(5) PRIMARY KEY, -- BCP 47 (ex: fr-FR, en-US)
    name VARCHAR(100) NOT NULL
);

-- ==========================================
-- TABLES MÉTIERS (Core Domain)
-- ==========================================

-- Table des Utilisateurs (Compte d'authentification — Identity & Access)
-- Note : nommée app_user pour éviter le conflit avec le mot réservé PostgreSQL USER
CREATE TABLE app_user (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'CLIENT', -- CLIENT, SUPPORT, ADMIN
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table des Clients
CREATE TABLE client (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES app_user(id) ON DELETE CASCADE,
    -- Champs optionnels au départ (Profilage progressif)
    date_of_birth DATE,
    address_street VARCHAR(255),
    address_city VARCHAR(100),
    address_zip_code VARCHAR(20),
    address_country_code VARCHAR(2) REFERENCES country(code),
    -- Préférences utilisateur
    language_code VARCHAR(5) DEFAULT 'fr-FR' REFERENCES language(code),
    -- Gestion sécurisée des paiements (Stripe)
    stripe_customer_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table des Agences
CREATE TABLE agency (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country_code VARCHAR(2) NOT NULL REFERENCES country(code)
);

-- Table des Codes Promotionnels
CREATE TABLE promo_code (
    code VARCHAR(50) PRIMARY KEY,
    client_id UUID REFERENCES client(id) ON DELETE CASCADE, -- NULL = pour tout le monde, UUID = réservé à ce client (ex: anniversaire)
    country_code VARCHAR(2) REFERENCES country(code),       -- NULL = international, ISO = limité à un pays spécifique
    discount_percentage DECIMAL(5, 2), -- ex: 15.00 pour 15%
    discount_amount DECIMAL(10, 2),    -- ou réduction fixe ex: 20.00€
    currency_code VARCHAR(3) REFERENCES currency(code), -- Utile si discount_amount est défini
    valid_until TIMESTAMPTZ
);

-- Table des Catégories de véhicules (Norme ACRISS)
CREATE TABLE vehicle_category (
    acriss_code VARCHAR(4) PRIMARY KEY,
    description TEXT NOT NULL
);

-- Table des Véhicules (Flotte physique individuelle)
CREATE TABLE vehicle (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_number VARCHAR(20) NOT NULL UNIQUE,         -- Immatriculation (ex: AB-123-CD)
    brand VARCHAR(100) NOT NULL,                             -- Marque (ex: Renault)
    model VARCHAR(100) NOT NULL,                             -- Modèle (ex: Megane)
    year SMALLINT NOT NULL,                                  -- Année de mise en circulation
    color VARCHAR(50),                                       -- Couleur (Nullable)
    mileage_km INTEGER NOT NULL DEFAULT 0,                   -- Kilométrage actuel
    status VARCHAR(50) NOT NULL DEFAULT 'AVAILABLE',         -- AVAILABLE, RENTED, MAINTENANCE, RETIRED
    vehicle_category_code VARCHAR(4) NOT NULL REFERENCES vehicle_category(acriss_code),
    home_agency_id UUID NOT NULL REFERENCES agency(id),      -- Agence d'attache administrative (immatriculation légale)
    current_agency_id UUID REFERENCES agency(id),            -- Agence physique actuelle (NULL si véhicule en location)
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table de Grille Tarifaire (Catalogue des prix)
CREATE TABLE pricing_grid (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_category_code VARCHAR(4) NOT NULL REFERENCES vehicle_category(acriss_code) ON DELETE CASCADE,
    base_daily_rate DECIMAL(10, 2) NOT NULL,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'EUR' REFERENCES currency(code),
    effective_from TIMESTAMPTZ NOT NULL,
    effective_to TIMESTAMPTZ -- Nullable : si null = tarif actuel en vigueur indéfiniment
);

-- Table des Réservations
CREATE TABLE reservation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES client(id) ON DELETE CASCADE,
    pickup_agency_id UUID NOT NULL REFERENCES agency(id),
    return_agency_id UUID NOT NULL REFERENCES agency(id),
    vehicle_category_code VARCHAR(4) NOT NULL REFERENCES vehicle_category(acriss_code),
    vehicle_id UUID REFERENCES vehicle(id),                  -- Nullable : assigné à la confirmation/prise en charge par l'agence Legacy via l'API
    promo_code VARCHAR(50) REFERENCES promo_code(code),
    pickup_time TIMESTAMPTZ NOT NULL,
    return_time TIMESTAMPTZ NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'EUR' REFERENCES currency(code),
    payment_option VARCHAR(50) NOT NULL DEFAULT 'PREPAID', -- PREPAID, PAY_ON_ARRIVAL
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING', -- PENDING, CONFIRMED, CANCELLED, COMPLETED
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_times CHECK (return_time > pickup_time)
);

-- Table des Paiements
CREATE TABLE payment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reservation_id UUID NOT NULL REFERENCES reservation(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'EUR' REFERENCES currency(code),
    payment_method VARCHAR(50) NOT NULL DEFAULT 'STRIPE_ONLINE', -- STRIPE_ONLINE, ON_SITE_CARD, ON_SITE_CASH
    stripe_payment_intent_id VARCHAR(255) UNIQUE, -- Peut être NULL si paiement sur place comptoir
    status VARCHAR(50) NOT NULL, -- SUCCEEDED, REFUNDED, FAILED, PENDING
    processed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table des Cautions (Deposits)
CREATE TABLE deposit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reservation_id UUID NOT NULL REFERENCES reservation(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'EUR' REFERENCES currency(code),
    terminal_hold_id VARCHAR(255) UNIQUE, -- Identifiant de l'empreinte TPE physique en agence
    status VARCHAR(50) NOT NULL DEFAULT 'HELD', -- HELD, RELEASED, CAPTURED
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table des Factures
CREATE TABLE invoice (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reservation_id UUID NOT NULL REFERENCES reservation(id) ON DELETE CASCADE,
    pdf_url VARCHAR(500) NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'STANDARD', -- STANDARD, REFUND, CANCELLATION_FEE
    issued_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table des Moyens de Paiement Enregistrés (Tokens Stripe)
CREATE TABLE saved_payment_method (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES client(id) ON DELETE CASCADE,
    stripe_payment_method_id VARCHAR(255) NOT NULL UNIQUE,
    card_brand VARCHAR(50),          -- Ex: Visa (métadonnée publique Stripe)
    card_last4 CHAR(4),              -- Ex: 4242 (métadonnée publique Stripe)
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table des Sessions de Chat (regroupement des échanges par conversation)
CREATE TABLE chat_session (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES client(id) ON DELETE SET NULL, -- Nullable : anonymisé si compte supprimé (RGPD)
    status VARCHAR(50) NOT NULL DEFAULT 'OPEN',              -- OPEN, CLOSED
    opened_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMPTZ                                    -- NULL tant que la session est ouverte
);

-- Table des Messages Chat
CREATE TABLE chat_message (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES chat_session(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES app_user(id) ON DELETE SET NULL, -- Nullable : SET NULL si compte supprimé (RGPD)
    sender_name VARCHAR(150) NOT NULL,  -- Dénormalisé pour l'immuabilité historique du chat
    role VARCHAR(50) NOT NULL,          -- CLIENT, SUPPORT
    type VARCHAR(50) NOT NULL,          -- CHAT, JOIN, LEAVE, CLOSE
    content TEXT,
    sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index pour optimiser les requêtes fréquentes
CREATE INDEX idx_reservation_client ON reservation(client_id);
CREATE INDEX idx_reservation_status ON reservation(status);
CREATE INDEX idx_payment_stripe ON payment(stripe_payment_intent_id);
CREATE INDEX idx_deposit_terminal ON deposit(terminal_hold_id);
CREATE INDEX idx_client_user ON client(user_id);
CREATE INDEX idx_saved_payment_method_client ON saved_payment_method(client_id);
CREATE INDEX idx_chat_message_sender ON chat_message(sender_id);
CREATE INDEX idx_chat_message_sent_at ON chat_message(sent_at);
CREATE INDEX idx_chat_message_session ON chat_message(session_id);
CREATE INDEX idx_chat_session_client ON chat_session(client_id);
-- Index Véhicules
CREATE INDEX idx_vehicle_category ON vehicle(vehicle_category_code);
CREATE INDEX idx_vehicle_status ON vehicle(status);
CREATE INDEX idx_vehicle_home_agency ON vehicle(home_agency_id);
CREATE INDEX idx_vehicle_current_agency ON vehicle(current_agency_id);
CREATE INDEX idx_reservation_vehicle ON reservation(vehicle_id);

-- Commentaires de tables et de colonnes pour la documentation (Data Dictionary)
-- Tables
COMMENT ON TABLE country IS 'Référentiel des pays (norme ISO 3166-1).';
COMMENT ON TABLE currency IS 'Référentiel des devises (norme ISO 4217).';
COMMENT ON TABLE language IS 'Référentiel des langues/locales (norme BCP 47).';
COMMENT ON TABLE app_user IS 'Compte d''authentification unifié pour tous les acteurs du système (clients et agents support). Nommé app_user pour éviter le conflit avec le mot réservé PostgreSQL USER.';
COMMENT ON TABLE client IS 'Profil métier du client final, lié à app_user par user_id. Ne contient que les données spécifiques au domaine métier (adresse, date de naissance, token Stripe). Les données d''authentification (email, mot de passe) sont dans app_user.';
COMMENT ON TABLE agency IS 'Liste des agences de location Your Car Your Way.';
COMMENT ON TABLE promo_code IS 'Codes promotionnels applicables lors de la réservation. S''ils sont liés à un client (anniversaire) le client_id est défini, sinon c''est global.';
COMMENT ON TABLE vehicle_category IS 'Référentiel des catégories de véhicules basé sur le standard international ACRISS.';
COMMENT ON TABLE vehicle IS 'Flotte physique des véhicules de Your Car Your Way. Chaque enregistrement représente un véhicule individuel identifié par son immatriculation. Les applications Legacy des agences maintiennent à jour le statut et l''agence courante via l''API IYCYW (opérations CRUD standard).';
COMMENT ON TABLE pricing_grid IS 'Catalogue des prix séparé en 3NF. Les tarifs sont liés à une catégorie et à une période de validité.';
COMMENT ON TABLE reservation IS 'Table centrale métier gérant le cycle de vie d''une location de véhicule.';
COMMENT ON TABLE payment IS 'Suivi des paiements et remboursements associés aux réservations. Mêle Stripe et paiements sur place.';
COMMENT ON TABLE deposit IS 'Gère les cautions isolément, permettant de suivre les retenues, libérations ou encaissements dissociés du paiement.';
COMMENT ON TABLE invoice IS 'Gestion des documents comptables légaux immuables.';
COMMENT ON TABLE saved_payment_method IS 'Moyens de paiement enregistrés, représentés par des tokens Stripe exclusivement. Aucune donnée bancaire brute n''est stockée (conformité PCI-DSS).';
COMMENT ON TABLE chat_session IS 'Session de support chat regroupant un échange entre un client et un agent. Le client_id devient NULL si le compte client est supprimé (anonymisation RGPD), mais la session et ses messages sont conservés (obligation légale / preuve de litige).';
COMMENT ON TABLE chat_message IS 'Messages du chat en direct entre clients et agents support. Toujours rattaché à une session (chat_session). Le sender_name est dénormalisé pour garantir l''immuabilité historique après suppression de compte (RGPD).';

-- Colonnes
COMMENT ON COLUMN app_user.role IS 'Rôle du compte : CLIENT (client final), SUPPORT (agent de chat), ADMIN (administrateur).';
COMMENT ON COLUMN client.stripe_customer_id IS 'Jeton (Token) sécurisé Stripe pour la facturation, évitant de stocker la carte (conformité PCI-DSS).';
COMMENT ON COLUMN client.language_code IS 'Langue préférée de l''utilisateur, utile pour l''envoi d''emails et l''édition des factures.';
COMMENT ON COLUMN promo_code.country_code IS 'Si renseigné, restreint l''utilisation du code promotionnel à ce pays uniquement.';
COMMENT ON COLUMN reservation.vehicle_id IS 'Véhicule physique spécifique assigné à cette réservation. Nullable : le client réserve une catégorie (vehicle_category_code) en ligne ; le véhicule individuel est assigné le jour J par l''agence via l''API IYCYW. L''assignation utilise SELECT FOR UPDATE pour garantir l''unicité (anti double-booking ACID).';
COMMENT ON COLUMN reservation.currency_code IS 'Devise utilisée pour cette réservation. Crucial pour gérer l''internationalisation des paiements.';
COMMENT ON COLUMN reservation.payment_option IS 'Choix du client : payer en ligne (PREPAID) ou en agence (PAY_ON_ARRIVAL).';
COMMENT ON COLUMN deposit.status IS 'État de la caution : HELD (retenue), RELEASED (relâchée), CAPTURED (encaissée suite à dommages).';
COMMENT ON COLUMN reservation.status IS 'État métier de la réservation : PENDING, CONFIRMED, CANCELLED, COMPLETED.';
COMMENT ON COLUMN payment.payment_method IS 'Moyen réel utilisé : STRIPE_ONLINE, ON_SITE_CARD, ON_SITE_CASH.';
COMMENT ON COLUMN payment.stripe_payment_intent_id IS 'Référence de transaction unique générée par Stripe. Peut être nulle si payé physiquement au comptoir.';
COMMENT ON COLUMN invoice.type IS 'Nature comptable du document : STANDARD (facture), REFUND (avoir), CANCELLATION_FEE (frais d''annulation).';
COMMENT ON COLUMN saved_payment_method.stripe_payment_method_id IS 'Identifiant unique du moyen de paiement côté Stripe (ex: pm_xxxx). Token opaque — jamais de numéro de carte.';
COMMENT ON COLUMN chat_session.client_id IS 'Identifiant du client ayant initié la session. SET NULL à la suppression du compte (RGPD — Art. 17). La session reste pour l''historique opérationnel.';
COMMENT ON COLUMN chat_message.sender_name IS 'Prénom ou pseudo de l''expéditeur au moment de l''envoi. Dénormalisé intentionnellement pour conserver l''historique même si le compte est supprimé.';
COMMENT ON COLUMN vehicle.registration_number IS 'Numéro d''immatriculation unique du véhicule (ex: AB-123-CD). Identifiant opérationnel utilisé par les agents en agence pour retrouver un véhicule précis.';
COMMENT ON COLUMN vehicle.status IS 'État opérationnel du véhicule : AVAILABLE (disponible en agence), RENTED (en location active), MAINTENANCE (en atelier), RETIRED (retiré de la flotte). Mis à jour par les applications Legacy via l''API IYCYW.';
COMMENT ON COLUMN vehicle.home_agency_id IS 'Agence d''attache administrative du véhicule (immatriculation légale). Valeur fixe, ne change pas lors des locations d''une agence vers une autre.';
COMMENT ON COLUMN vehicle.current_agency_id IS 'Agence où se trouve physiquement le véhicule à l''instant T. NULL si le véhicule est en cours de location. Mis à jour par le Legacy via l''API à chaque prise en charge (NULL) et à chaque retour (agence de retour). Permet de connaître la répartition de la flotte en temps réel.';
