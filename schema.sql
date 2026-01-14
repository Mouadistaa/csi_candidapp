create type role_enum as enum ('ETUDIANT', 'ENTREPRISE', 'ENSEIGNANT', 'SECRETAIRE', 'ADMIN');

alter type role_enum owner to m1user1_02;

create type rc_statut_enum as enum ('EN_ATTENTE', 'VALIDE', 'REFUSE');

alter type rc_statut_enum owner to m1user1_02;

create type offre_type_enum as enum ('STAGE', 'ALTERNANCE', 'EMPLOI', 'VIE');

alter type offre_type_enum owner to m1user1_02;

create type validation_statut_enum as enum ('BROUILLON', 'EN_ATTENTE', 'VALIDE', 'REFUSE');

alter type validation_statut_enum owner to m1user1_02;

create type cand_statut_enum as enum ('EN_ATTENTE', 'ENTRETIEN', 'RETENU', 'REFUSE', 'ANNULE');

alter type cand_statut_enum owner to m1user1_02;

create type renoncement_type_enum as enum ('etudiant', 'systeme', 'entreprise');

alter type renoncement_type_enum owner to m1user1_02;

create type journal_type_enum as enum ('CONNEXION', 'CREATION', 'MODIFICATION', 'SUPPRESSION', 'ERREUR');

alter type journal_type_enum owner to m1user1_02;

create table "Utilisateur"
(
    id            serial
        primary key,
    email         text                                   not null
        unique,
    password_hash text                                   not null,
    role          role_enum                              not null,
    actif         boolean                  default true,
    created_at    timestamp with time zone default now() not null,
    nom           text
);

alter table "Utilisateur"
    owner to m1user1_02;

create table "Etudiant"
(
    etudiant_id    serial
        primary key,
    utilisateur_id integer not null
        unique
        constraint fk_etudiant_user
            references "Utilisateur"
            on delete cascade,
    nom            text    not null,
    prenom         text    not null,
    formation      text    not null,
    promo          text,
    en_recherche   boolean default false,
    profil_visible boolean default false,
    cv_url         text
);

alter table "Etudiant"
    owner to m1user1_02;

create table "Entreprise"
(
    entreprise_id  serial
        primary key,
    utilisateur_id integer not null
        unique
        constraint fk_entreprise_user
            references "Utilisateur"
            on delete cascade,
    raison_sociale text    not null,
    siret          text,
    pays           text    not null,
    ville          text,
    adresse        text,
    site_web       text,
    contact_nom    text,
    contact_email  text
);

alter table "Entreprise"
    owner to m1user1_02;

create table "Enseignant"
(
    enseignant_id  serial
        primary key,
    utilisateur_id integer not null
        unique
        constraint fk_enseignant_user
            references "Utilisateur"
            on delete cascade
);

alter table "Enseignant"
    owner to m1user1_02;

create table "Secretaire"
(
    secretaire_id  serial
        primary key,
    utilisateur_id integer not null
        unique
        constraint fk_secretaire_user
            references "Utilisateur"
            on delete cascade,
    en_conge       boolean
);

alter table "Secretaire"
    owner to m1user1_02;

create table "AttestationRC"
(
    etudiant_id     integer                   not null
        primary key
        constraint fk_attestation_etudiant
            references "Etudiant"
            on delete cascade,
    statut          rc_statut_enum            not null,
    fichier_url     text                      not null,
    date_depot      date default CURRENT_DATE not null,
    date_validation date
);

alter table "AttestationRC"
    owner to m1user1_02;

create table "Offre"
(
    id                 serial
        primary key,
    entreprise_id      integer                   not null
        constraint fk_offre_entreprise
            references "Entreprise"
            on delete cascade,
    type               offre_type_enum           not null,
    titre              text                      not null,
    description        text,
    competences        text,
    localisation_pays  text                      not null,
    localisation_ville text,
    duree_mois         integer                   not null,
    remuneration       numeric(10, 2)            not null,
    date_debut         date                      not null,
    date_expiration    date                      not null,
    statut_validation  validation_statut_enum    not null,
    date_soumission    date default CURRENT_DATE not null,
    date_validation    date,
    constraint chk_offre_dates
        check (date_expiration >= date_debut)
);

alter table "Offre"
    owner to m1user1_02;

grant usage on sequence "Offre_id_seq" to role_entreprise;

create table "RegleLegale"
(
    id               serial
        primary key,
    pays             text            not null,
    type_contrat     offre_type_enum not null,
    remuneration_min numeric(10, 2)  not null,
    unite            text            not null,
    duree_min_mois   integer,
    duree_max_mois   integer,
    date_effet       date            not null,
    date_fin         date
);

alter table "RegleLegale"
    owner to m1user1_02;

grant usage on sequence "RegleLegale_id_seq" to role_enseignant;

create table "Offre_RegleLegale"
(
    offre_id        integer not null
        constraint fk_orl_offre
            references "Offre"
            on delete cascade,
    regle_legale_id integer not null
        constraint fk_orl_regle
            references "RegleLegale"
            on delete cascade,
    primary key (offre_id, regle_legale_id)
);

alter table "Offre_RegleLegale"
    owner to m1user1_02;

create table "Candidature"
(
    id               serial
        primary key,
    offre_id         integer                   not null
        constraint fk_cand_offre
            references "Offre"
            on delete cascade,
    etudiant_id      integer                   not null
        constraint fk_cand_etudiant
            references "Etudiant"
            on delete cascade,
    date_candidature date default CURRENT_DATE not null,
    source           text,
    statut           cand_statut_enum          not null
);

alter table "Candidature"
    owner to m1user1_02;

grant usage on sequence "Candidature_id_seq" to role_etudiant;

create table "Affectation"
(
    id              serial
        primary key,
    candidature_id  integer not null
        unique
        constraint fk_affectation_cand
            references "Candidature"
            on delete cascade,
    date_validation date    not null
);

alter table "Affectation"
    owner to m1user1_02;

create table "Renoncement"
(
    id               serial
        primary key,
    candidature_id   integer                   not null
        constraint fk_renoncement_cand
            references "Candidature"
            on delete cascade,
    type             renoncement_type_enum     not null,
    justification    text,
    date_renoncement date default CURRENT_DATE not null
);

alter table "Renoncement"
    owner to m1user1_02;

create table "JournalEvenement"
(
    id             bigserial
        primary key,
    utilisateur_id integer
        constraint fk_journal_user
            references "Utilisateur"
            on delete set null,
    type           journal_type_enum not null,
    payload        text,
    created_at     timestamp with time zone default now()
);

alter table "JournalEvenement"
    owner to m1user1_02;

create view v_offres_visibles_etudiant
            (offre_id, entreprise_nom, entreprise_site, entreprise_ville, titre, type, description, competences,
             localisation_ville, localisation_pays, duree_mois, remuneration, date_debut, date_expiration, est_expiree)
as
SELECT o.id                             AS offre_id,
       e.raison_sociale                 AS entreprise_nom,
       e.site_web                       AS entreprise_site,
       e.ville                          AS entreprise_ville,
       o.titre,
       o.type,
       o.description,
       o.competences,
       o.localisation_ville,
       o.localisation_pays,
       o.duree_mois,
       o.remuneration,
       o.date_debut,
       o.date_expiration,
       o.date_expiration < CURRENT_DATE AS est_expiree
FROM "Offre" o
         JOIN "Entreprise" e ON o.entreprise_id = e.entreprise_id
WHERE o.statut_validation = 'VALIDE'::validation_statut_enum;

alter table v_offres_visibles_etudiant
    owner to m1user1_02;

grant select on v_offres_visibles_etudiant to role_etudiant;

create view v_profil_entreprise
            (utilisateur_id, email, role, entreprise_id, raison_sociale, siret, pays, ville, adresse, site_web,
             contact_nom, contact_email)
as
SELECT u.id AS utilisateur_id,
       u.email,
       u.role,
       e.entreprise_id,
       e.raison_sociale,
       e.siret,
       e.pays,
       e.ville,
       e.adresse,
       e.site_web,
       e.contact_nom,
       e.contact_email
FROM "Utilisateur" u
         JOIN "Entreprise" e ON u.id = e.utilisateur_id;

alter table v_profil_entreprise
    owner to m1user1_02;

create view v_profil_etudiant
            (utilisateur_id, email, role, etudiant_id, nom, prenom, formation, promo, en_recherche, profil_visible,
             cv_url) as
SELECT u.id AS utilisateur_id,
       u.email,
       u.role,
       et.etudiant_id,
       et.nom,
       et.prenom,
       et.formation,
       et.promo,
       et.en_recherche,
       et.profil_visible,
       et.cv_url
FROM "Utilisateur" u
         JOIN "Etudiant" et ON u.id = et.utilisateur_id;

alter table v_profil_etudiant
    owner to m1user1_02;

create view v_sys_auth_modification(id, email, password_hash) as
SELECT "Utilisateur".id,
       "Utilisateur".email,
       "Utilisateur".password_hash
FROM "Utilisateur";

alter table v_sys_auth_modification
    owner to m1user1_02;

create view v_action_postuler(offre_id, etudiant_id, source) as
SELECT "Candidature".offre_id,
       "Candidature".etudiant_id,
       "Candidature".source
FROM "Candidature";

alter table v_action_postuler
    owner to m1user1_02;

grant insert on v_action_postuler to role_etudiant;

create view v_action_creer_offre
            (id, entreprise_id, type, titre, description, competences, localisation_pays, localisation_ville,
             duree_mois, remuneration, date_debut, date_expiration)
as
SELECT "Offre".id,
       "Offre".entreprise_id,
       "Offre".type,
       "Offre".titre,
       "Offre".description,
       "Offre".competences,
       "Offre".localisation_pays,
       "Offre".localisation_ville,
       "Offre".duree_mois,
       "Offre".remuneration,
       "Offre".date_debut,
       "Offre".date_expiration
FROM "Offre";

alter table v_action_creer_offre
    owner to m1user1_02;

grant insert on v_action_creer_offre to role_entreprise;

create view v_mes_candidatures_etudiant
            (utilisateur_id, etudiant_id, candidature_id, date_candidature, statut_candidature, source, offre_id,
             offre_titre, offre_type, remuneration, duree_mois, lieu_mission, statut_actuel_offre, entreprise_nom,
             entreprise_ville, entreprise_site)
as
SELECT u.id                 AS utilisateur_id,
       et.etudiant_id,
       c.id                 AS candidature_id,
       c.date_candidature,
       c.statut             AS statut_candidature,
       c.source,
       o.id                 AS offre_id,
       o.titre              AS offre_titre,
       o.type               AS offre_type,
       o.remuneration,
       o.duree_mois,
       o.localisation_ville AS lieu_mission,
       o.statut_validation  AS statut_actuel_offre,
       e.raison_sociale     AS entreprise_nom,
       e.ville              AS entreprise_ville,
       e.site_web           AS entreprise_site
FROM "Candidature" c
         JOIN "Etudiant" et ON c.etudiant_id = et.etudiant_id
         JOIN "Utilisateur" u ON et.utilisateur_id = u.id
         JOIN "Offre" o ON c.offre_id = o.id
         JOIN "Entreprise" e ON o.entreprise_id = e.entreprise_id;

alter table v_mes_candidatures_etudiant
    owner to m1user1_02;

grant select on v_mes_candidatures_etudiant to role_etudiant;

create view v_action_annuler_candidature(candidature_id, etudiant_id, statut) as
SELECT "Candidature".id AS candidature_id,
       "Candidature".etudiant_id,
       "Candidature".statut
FROM "Candidature";

alter table v_action_annuler_candidature
    owner to m1user1_02;

grant select, update on v_action_annuler_candidature to role_etudiant;

create view v_offres_conformite
            (offre_id, titre, raison_sociale, offre_remuneration, offre_duree, localisation_pays, legal_salaire_min,
             legal_duree_min, est_conforme, raison_non_conformite, statut_validation, date_soumission, type,
             localisation_ville, entreprise_site, entreprise_ville, date_debut, date_expiration)
as
SELECT o.id               AS offre_id,
       o.titre,
       e.raison_sociale,
       o.remuneration     AS offre_remuneration,
       o.duree_mois       AS offre_duree,
       o.localisation_pays,
       r.remuneration_min AS legal_salaire_min,
       r.duree_min_mois   AS legal_duree_min,
       CASE
           WHEN r.id IS NULL THEN true
           WHEN o.remuneration < r.remuneration_min THEN false
           WHEN o.duree_mois < r.duree_min_mois THEN false
           ELSE true
           END            AS est_conforme,
       concat(
               CASE
                   WHEN r.id IS NULL THEN ''::text
                   WHEN o.remuneration < r.remuneration_min THEN
                       ('Salaire insuffisant ('::text || r.remuneration_min) || ' min). '::text
                   ELSE ''::text
                   END,
               CASE
                   WHEN r.id IS NULL THEN ''::text
                   WHEN o.duree_mois < r.duree_min_mois THEN ('Durée trop courte ('::text || r.duree_min_mois) ||
                                                             ' mois min).'::text
                   ELSE ''::text
                   END)   AS raison_non_conformite,
       o.statut_validation,
       o.date_soumission,
       o.type,
       o.localisation_ville,
       e.site_web         AS entreprise_site,
       e.ville            AS entreprise_ville,
       o.date_debut,
       o.date_expiration
FROM "Offre" o
         JOIN "Entreprise" e ON o.entreprise_id = e.entreprise_id
         LEFT JOIN "RegleLegale" r
                   ON o.localisation_pays = r.pays AND r.type_contrat = o.type AND CURRENT_DATE >= r.date_effet AND
                      (r.date_fin IS NULL OR r.date_fin >= CURRENT_DATE);

alter table v_offres_conformite
    owner to m1user1_02;

grant select on v_offres_conformite to role_enseignant;

create view v_affectations_a_valider
            (candidature_id, etudiant_nom, etudiant_prenom, raison_sociale, offre_titre, date_debut,
             date_candidature) as
SELECT c.id       AS candidature_id,
       etu.nom    AS etudiant_nom,
       etu.prenom AS etudiant_prenom,
       ent.raison_sociale,
       o.titre    AS offre_titre,
       o.date_debut,
       c.date_candidature
FROM "Candidature" c
         JOIN "Etudiant" etu ON c.etudiant_id = etu.etudiant_id
         JOIN "Offre" o ON c.offre_id = o.id
         JOIN "Entreprise" ent ON o.entreprise_id = ent.entreprise_id
         LEFT JOIN "Affectation" a ON c.id = a.candidature_id
WHERE c.statut = 'RETENU'::cand_statut_enum
  AND a.id IS NULL;

alter table v_affectations_a_valider
    owner to m1user1_02;

grant select on v_affectations_a_valider to role_enseignant;

create view v_dashboard_enseignant_stats(nb_offres_a_valider, nb_affectations_a_valider, nb_alertes_conformite) as
SELECT (SELECT count(*) AS count
        FROM "Offre"
        WHERE "Offre".statut_validation = 'EN_ATTENTE'::validation_statut_enum)                                           AS nb_offres_a_valider,
       (SELECT count(*) AS count
        FROM v_affectations_a_valider)                                                                                    AS nb_affectations_a_valider,
       (SELECT count(*) AS count
        FROM v_offres_conformite
        WHERE v_offres_conformite.est_conforme = false
          AND (v_offres_conformite.offre_id IN (SELECT "Offre".id
                                                FROM "Offre"
                                                WHERE "Offre".statut_validation = 'EN_ATTENTE'::validation_statut_enum))) AS nb_alertes_conformite;

alter table v_dashboard_enseignant_stats
    owner to m1user1_02;

grant select on v_dashboard_enseignant_stats to role_enseignant;

create view v_action_enseignant_review_offre(offre_id, statut_validation) as
SELECT "Offre".id AS offre_id,
       "Offre".statut_validation
FROM "Offre";

alter table v_action_enseignant_review_offre
    owner to m1user1_02;

grant update on v_action_enseignant_review_offre to role_enseignant;

create view v_action_enseignant_valider_affectation(candidature_id) as
SELECT "Affectation".candidature_id
FROM "Affectation";

alter table v_action_enseignant_valider_affectation
    owner to m1user1_02;

grant insert on v_action_enseignant_valider_affectation to role_enseignant;

create view v_referentiel_legal
            (regle_id, pays, type_contrat, remuneration_min, duree_min_mois, duree_max_mois, date_effet, date_fin,
             unite) as
SELECT "RegleLegale".id AS regle_id,
       "RegleLegale".pays,
       "RegleLegale".type_contrat,
       "RegleLegale".remuneration_min,
       "RegleLegale".duree_min_mois,
       "RegleLegale".duree_max_mois,
       "RegleLegale".date_effet,
       "RegleLegale".date_fin,
       "RegleLegale".unite
FROM "RegleLegale"
WHERE "RegleLegale".date_fin IS NULL
   OR "RegleLegale".date_fin > CURRENT_DATE
ORDER BY "RegleLegale".pays, "RegleLegale".type_contrat;

alter table v_referentiel_legal
    owner to m1user1_02;

create view v_archives_stages
            (affectation_id, etudiant_nom_complet, etudiant_promo, entreprise_nom, offre_titre, date_debut_stage,
             date_fin_stage, date_validation_finale)
as
SELECT a.id                                                                 AS affectation_id,
       (e.nom || ' '::text) || e.prenom                                     AS etudiant_nom_complet,
       e.promo                                                              AS etudiant_promo,
       ent.raison_sociale                                                   AS entreprise_nom,
       o.titre                                                              AS offre_titre,
       o.date_debut                                                         AS date_debut_stage,
       (o.date_debut + ((o.duree_mois || ' months'::text)::interval))::date AS date_fin_stage,
       a.date_validation                                                    AS date_validation_finale
FROM "Affectation" a
         JOIN "Candidature" c ON a.candidature_id = c.id
         JOIN "Etudiant" e ON c.etudiant_id = e.etudiant_id
         JOIN "Offre" o ON c.offre_id = o.id
         JOIN "Entreprise" ent ON o.entreprise_id = ent.entreprise_id;

alter table v_archives_stages
    owner to m1user1_02;

create view v_dashboard_secretaire_stats
            (nb_etudiants_total, nb_etudiants_en_recherche, nb_attestations_a_valider, nb_stages_actes,
             nb_entreprises_partenaires) as
SELECT (SELECT count(*) AS count
        FROM "Etudiant")                               AS nb_etudiants_total,
       (SELECT count(*) AS count
        FROM "Etudiant"
        WHERE "Etudiant".en_recherche = true)          AS nb_etudiants_en_recherche,
       (SELECT count(*) AS count
        FROM "AttestationRC"
        WHERE "AttestationRC".date_validation IS NULL) AS nb_attestations_a_valider,
       (SELECT count(*) AS count
        FROM "Affectation")                            AS nb_stages_actes,
       (SELECT count(*) AS count
        FROM "Entreprise")                             AS nb_entreprises_partenaires;

alter table v_dashboard_secretaire_stats
    owner to m1user1_02;

create view v_action_deposer_attestation_rc(etudiant_id, fichier_url) as
SELECT "AttestationRC".etudiant_id,
       "AttestationRC".fichier_url
FROM "AttestationRC";

alter table v_action_deposer_attestation_rc
    owner to m1user1_03;

grant insert, update on v_action_deposer_attestation_rc to role_etudiant;

create view v_user_entreprise(utilisateur_id, entreprise_id) as
SELECT "Entreprise".utilisateur_id,
       "Entreprise".entreprise_id
FROM "Entreprise";

alter table v_user_entreprise
    owner to m1user1_04;

create view v_dashboard_entreprise_stats(entreprise_id, active, pending, candidatures) as
SELECT o.entreprise_id,
       count(*) FILTER (WHERE o.statut_validation = 'VALIDE'::validation_statut_enum)     AS active,
       count(*) FILTER (WHERE o.statut_validation = 'EN_ATTENTE'::validation_statut_enum) AS pending,
       count(c.id)                                                                        AS candidatures
FROM "Offre" o
         LEFT JOIN "Candidature" c ON c.offre_id = o.id
GROUP BY o.entreprise_id;

alter table v_dashboard_entreprise_stats
    owner to m1user1_04;

create view v_mes_offres_entreprise
            (id, entreprise_id, type, titre, description, competences, localisation_pays, localisation_ville,
             duree_mois, remuneration, date_debut, date_expiration, statut_validation, date_soumission, date_validation,
             nb_candidats)
as
SELECT o.id,
       o.entreprise_id,
       o.type,
       o.titre,
       o.description,
       o.competences,
       o.localisation_pays,
       o.localisation_ville,
       o.duree_mois,
       o.remuneration,
       o.date_debut,
       o.date_expiration,
       o.statut_validation,
       o.date_soumission,
       o.date_validation,
       count(c.id) AS nb_candidats
FROM "Offre" o
         LEFT JOIN "Candidature" c ON c.offre_id = o.id
GROUP BY o.id;

alter table v_mes_offres_entreprise
    owner to m1user1_04;

create view v_candidatures_recues_entreprise
            (entreprise_id, candidature_id, statut, date_candidature, offre_id, offre_titre, etudiant_id, nom, prenom,
             cv_url, formation)
as
SELECT o.entreprise_id,
       c.id    AS candidature_id,
       c.statut,
       c.date_candidature,
       o.id    AS offre_id,
       o.titre AS offre_titre,
       e.etudiant_id,
       e.nom,
       e.prenom,
       e.cv_url,
       e.formation
FROM "Candidature" c
         JOIN "Offre" o ON o.id = c.offre_id
         JOIN "Etudiant" e ON e.etudiant_id = c.etudiant_id;

alter table v_candidatures_recues_entreprise
    owner to m1user1_04;

create view v_action_entreprise_decider_candidature(candidature_id, entreprise_id, statut) as
SELECT c.id AS candidature_id,
       o.entreprise_id,
       c.statut
FROM "Candidature" c
         JOIN "Offre" o ON o.id = c.offre_id;

alter table v_action_entreprise_decider_candidature
    owner to m1user1_04;

create view v_attestations_rc_a_valider(etudiant_id, nom, prenom, promo, fichier_url, date_depot, statut) as
SELECT a.etudiant_id,
       e.nom,
       e.prenom,
       e.promo,
       a.fichier_url,
       a.date_depot,
       a.statut
FROM "AttestationRC" a
         JOIN "Etudiant" e ON e.etudiant_id = a.etudiant_id
WHERE a.statut = 'EN_ATTENTE'::rc_statut_enum
ORDER BY a.date_depot DESC;

alter table v_attestations_rc_a_valider
    owner to m1user1_04;

grant select on v_attestations_rc_a_valider to role_secretaire;

create view v_action_valider_attestation_rc
            (etudiant_id, statut, date_validation, decision, motif_refus, secretaire_id) as
SELECT a.etudiant_id,
       a.statut,
       a.date_validation,
       NULL::text    AS decision,
       NULL::text    AS motif_refus,
       NULL::integer AS secretaire_id
FROM "AttestationRC" a;

alter table v_action_valider_attestation_rc
    owner to m1user1_04;

grant select, update on v_action_valider_attestation_rc to role_secretaire;

create view v_secretaire_by_user(secretaire_id, utilisateur_id) as
SELECT "Secretaire".secretaire_id,
       "Secretaire".utilisateur_id
FROM "Secretaire";

alter table v_secretaire_by_user
    owner to m1user1_04;

create view v_attestation_rc_etudiant (utilisateur_id, etudiant_id, statut, fichier_url, date_depot, date_validation) as
SELECT u.id AS utilisateur_id,
       e.etudiant_id,
       a.statut,
       a.fichier_url,
       a.date_depot,
       a.date_validation
FROM "Utilisateur" u
         JOIN "Etudiant" e ON e.utilisateur_id = u.id
         LEFT JOIN "AttestationRC" a ON a.etudiant_id = e.etudiant_id;

alter table v_attestation_rc_etudiant
    owner to m1user1_03;

create view v_action_modifier_referentiel_legal
            (regle_id, pays, type_contrat, remuneration_min, unite, duree_min_mois, duree_max_mois, date_effet,
             date_fin) as
SELECT r.id AS regle_id,
       r.pays,
       r.type_contrat,
       r.remuneration_min,
       r.unite,
       r.duree_min_mois,
       r.duree_max_mois,
       r.date_effet,
       r.date_fin
FROM "RegleLegale" r;

alter table v_action_modifier_referentiel_legal
    owner to m1user1_03;

create function trg_action_postuler_func() returns trigger
    language plpgsql
as
$$
DECLARE
    v_statut_offre validation_statut_enum;
BEGIN
    -- 1. Vérification Offre (Inchangé)
    SELECT statut_validation INTO v_statut_offre
    FROM "Offre" WHERE id = NEW.offre_id;

    IF v_statut_offre IS DISTINCT FROM 'VALIDE' THEN
        RAISE EXCEPTION 'Impossible de postuler : Cette offre n''est pas disponible.';
    END IF;

    -- 2. Vérification Doublon (MODIFIÉ)
    -- On vérifie s'il existe déjà une candidature pour cette offre/étudiant
    -- MAIS on ignore celles qui sont 'ANNULE'.
    IF EXISTS (
        SELECT 1
        FROM "Candidature"
        WHERE offre_id = NEW.offre_id
          AND etudiant_id = NEW.etudiant_id
          AND statut != 'ANNULE' -- C'est ici que la magie opère
    ) THEN
        RAISE EXCEPTION 'Vous avez déjà une candidature pour cette offre.';
    END IF;

    -- 3. Insertion réelle (Inchangé)
    INSERT INTO "Candidature" (offre_id, etudiant_id, source, statut, date_candidature)
    VALUES (NEW.offre_id, NEW.etudiant_id, NEW.source, 'EN_ATTENTE', CURRENT_DATE);

    RETURN NEW;
END;
$$;

alter function trg_action_postuler_func() owner to m1user1_02;

create trigger trg_postuler_insert
    instead of insert
    on v_action_postuler
    for each row
execute procedure trg_action_postuler_func();

create function trg_action_creer_offre_func() returns trigger
    language plpgsql
as
$$
BEGIN
    -- Création d'une offre : on force un statut cohérent avec la matrice métier
    -- et on bannit toute création en BROUILLON.
    INSERT INTO "Offre" (
        entreprise_id,
        type,
        titre,
        description,
        competences,
        localisation_pays,
        localisation_ville,
        duree_mois,
        remuneration,
        date_debut,
        date_expiration,
        statut_validation,
        date_soumission,
        date_validation
    )
    VALUES (
               NEW.entreprise_id,
               NEW.type,
               NEW.titre,
               NEW.description,
               NEW.competences,
               NEW.localisation_pays,
               NEW.localisation_ville,
               NEW.duree_mois,
               NEW.remuneration,
               NEW.date_debut,
               NEW.date_expiration,
               'EN_ATTENTE',   -- ✅ forcé : jamais BROUILLON à la création
               CURRENT_DATE,   -- ✅ date soumission automatique
               NULL            -- ✅ pas validée à la création
           )
    RETURNING id INTO NEW.id;

    RETURN NEW;
END;
$$;

alter function trg_action_creer_offre_func() owner to m1user1_02;

create trigger trg_creer_offre_insert
    instead of insert
    on v_action_creer_offre
    for each row
execute procedure trg_action_creer_offre_func();

create function trg_action_annuler_candidature_func() returns trigger
    language plpgsql
as
$$
DECLARE
    v_statut_actuel cand_statut_enum;
BEGIN
    -- 1. Récupérer le statut actuel réel dans la table
    SELECT statut INTO v_statut_actuel FROM "Candidature" WHERE id = OLD.candidature_id;

    -- 2. Vérification : On ne peut annuler que si c'est "EN_ATTENTE"
    IF v_statut_actuel IS DISTINCT FROM 'EN_ATTENTE' THEN
        RAISE EXCEPTION 'Impossible d''annuler cette candidature. Elle a déjà été traitée ou annulée (Statut actuel : %)', v_statut_actuel;
    END IF;

    -- 3. Exécution de l'annulation
    -- On force le statut à 'ANNULE' peu importe ce que l'utilisateur envoie
    UPDATE "Candidature"
    SET statut = 'ANNULE'
    WHERE id = OLD.candidature_id;

    RETURN NEW;
END;
$$;

alter function trg_action_annuler_candidature_func() owner to m1user1_02;

create trigger trg_annuler_candidature_update
    instead of update
    on v_action_annuler_candidature
    for each row
execute procedure trg_action_annuler_candidature_func();

create function trg_referentiel_insert_func() returns trigger
    language plpgsql
as
$$
BEGIN
    INSERT INTO "RegleLegale" (
        pays, type_contrat, remuneration_min, unite,
        duree_min_mois, duree_max_mois, date_effet, date_fin
        -- statut_actif supprimé
    ) VALUES (
                 NEW.pays, NEW.type_contrat, NEW.remuneration_min, 'EUR_MOIS',
                 NEW.duree_min_mois, NEW.duree_max_mois,
                 COALESCE(NEW.date_effet, CURRENT_DATE),
                 NEW.date_fin
             );
    INSERT INTO "JournalEvenement"(utilisateur_id, type, payload)
    VALUES (
               NULL,
               'MODIFICATION',
               jsonb_build_object(
                       'action', 'UPDATE_REGLE_LEGALE',
                       'regle_id', OLD.regle_id
               )::text
           );
    RETURN NEW;
END;
$$;

alter function trg_referentiel_insert_func() owner to m1user1_02;

create trigger trg_referentiel_insert
    instead of insert
    on v_action_modifier_referentiel_legal
    for each row
execute procedure trg_referentiel_insert_func();

create function trg_referentiel_update_func() returns trigger
    language plpgsql
as
$$
BEGIN
    UPDATE "RegleLegale"
    SET
        pays             = NEW.pays,
        type_contrat     = NEW.type_contrat,
        remuneration_min = NEW.remuneration_min,
        unite            = NEW.unite,
        duree_min_mois   = NEW.duree_min_mois,
        duree_max_mois   = NEW.duree_max_mois,
        date_effet       = NEW.date_effet,
        date_fin         = NEW.date_fin
    WHERE id = OLD.regle_id;

    INSERT INTO "JournalEvenement"(utilisateur_id, type, payload)
    VALUES (
               NULL,
               'MODIFICATION',
               jsonb_build_object(
                       'action', 'UPDATE_REGLE_LEGALE',
                       'regle_id', OLD.regle_id
               )::text
           );
    RETURN NEW;
END;
$$;

alter function trg_referentiel_update_func() owner to m1user1_02;

create trigger trg_referentiel_update
    instead of update
    on v_action_modifier_referentiel_legal
    for each row
execute procedure trg_referentiel_update_func();

create function trg_referentiel_delete_func() returns trigger
    language plpgsql
as
$$
BEGIN
    DELETE FROM "RegleLegale"
    WHERE id = OLD.regle_id;
    INSERT INTO "JournalEvenement"(utilisateur_id, type, payload)
    VALUES (
               NULL,
               'MODIFICATION',
               jsonb_build_object(
                       'action', 'UPDATE_REGLE_LEGALE',
                       'regle_id', OLD.regle_id
               )::text
           );

    RETURN OLD;
END;
$$;

alter function trg_referentiel_delete_func() owner to m1user1_02;

create trigger trg_referentiel_delete
    instead of delete
    on v_action_modifier_referentiel_legal
    for each row
execute procedure trg_referentiel_delete_func();

create function trg_ens_review_offre_func() returns trigger
    language plpgsql
as
$$
BEGIN
    IF NEW.statut_validation NOT IN ('VALIDE', 'REFUSE') THEN
        RAISE EXCEPTION 'Statut invalide. Utilisez VALIDE ou REFUSE.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM "Offre"
        WHERE id = NEW.offre_id
          AND statut_validation <> 'EN_ATTENTE'
    ) THEN
        RAISE EXCEPTION 'Offre déjà traitée : seule une offre EN_ATTENTE peut être revue.';
    END IF;

    UPDATE "Offre"
    SET statut_validation = NEW.statut_validation,
        date_validation = CURRENT_DATE
    WHERE id = NEW.offre_id;

    RETURN NEW;
END;
$$;

alter function trg_ens_review_offre_func() owner to m1user1_02;

create trigger trg_ens_review_offre_update
    instead of update
    on v_action_enseignant_review_offre
    for each row
execute procedure trg_ens_review_offre_func();

create function trg_ens_valider_affectation_func() returns trigger
    language plpgsql
as
$$
BEGIN
    -- Création de l'affectation finale
    INSERT INTO "Affectation" (candidature_id, date_validation)
    VALUES (NEW.candidature_id, CURRENT_DATE);

    -- Optionnel : On pourrait passer le statut Candidature à 'SIGNE' ou autre ici

    RETURN NEW;
END;
$$;

alter function trg_ens_valider_affectation_func() owner to m1user1_02;

create trigger trg_ens_valider_affectation_insert
    instead of insert
    on v_action_enseignant_valider_affectation
    for each row
execute procedure trg_ens_valider_affectation_func();

create function trg_action_deposer_attestation_rc_func() returns trigger
    language plpgsql
as
$$
DECLARE
    v_statut_existant rc_statut_enum;
BEGIN
    -- On regarde si une attestation existe déjà pour cet étudiant
    SELECT statut
    INTO v_statut_existant
    FROM "AttestationRC"
    WHERE etudiant_id = NEW.etudiant_id;

    -- Cas A : aucune attestation existante -> insertion
    IF NOT FOUND THEN
        INSERT INTO "AttestationRC" (
            etudiant_id,
            statut,
            fichier_url,
            date_depot,
            date_validation
        ) VALUES (
                     NEW.etudiant_id,
                     'EN_ATTENTE',
                     NEW.fichier_url,
                     CURRENT_DATE,
                     NULL
                 );

        RETURN NEW;
    END IF;

    -- Cas B : attestation existante
    IF v_statut_existant = 'REFUSE' THEN
        -- Redépôt autorisé : on remplace le fichier et on repasse en EN_ATTENTE
        UPDATE "AttestationRC"
        SET fichier_url     = NEW.fichier_url,
            statut          = 'EN_ATTENTE',
            date_depot      = CURRENT_DATE,
            date_validation = NULL
        WHERE etudiant_id = NEW.etudiant_id;

        RETURN NEW;
    END IF;

    -- Cas C : EN_ATTENTE ou VALIDE -> dépôt interdit
    RAISE EXCEPTION
        'Dépôt impossible : une attestation RC est déjà % (redépôt autorisé uniquement après REFUSE).',
        v_statut_existant;

END;
$$;

alter function trg_action_deposer_attestation_rc_func() owner to m1user1_03;

create trigger trg_deposer_attestation_rc_insert
    instead of insert
    on v_action_deposer_attestation_rc
    for each row
execute procedure trg_action_deposer_attestation_rc_func();

create function trg_action_entreprise_decider_candidature_func() returns trigger
    language plpgsql
as
$$
BEGIN
    -- Sécurité : on met à jour uniquement si la candidature appartient à l'entreprise donnée
    UPDATE "Candidature" c
    SET statut = NEW.statut
    FROM "Offre" o
    WHERE c.id = NEW.candidature_id
      AND o.id = c.offre_id
      AND o.entreprise_id = NEW.entreprise_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Update interdit ou candidature introuvable (candidature_id=% / entreprise_id=%)',
            NEW.candidature_id, NEW.entreprise_id;
    END IF;

    RETURN NEW;
END;
$$;

alter function trg_action_entreprise_decider_candidature_func() owner to m1user1_04;

create trigger trg_action_entreprise_decider_candidature_update
    instead of update
    on v_action_entreprise_decider_candidature
    for each row
execute procedure trg_action_entreprise_decider_candidature_func();

create function trg_action_valider_attestation_rc_func() returns trigger
    language plpgsql
as
$$
DECLARE
    v_current_statut rc_statut_enum;
    v_user_id integer;
BEGIN
    -- Contrôle décision
    IF NEW.decision IS NULL OR NEW.decision NOT IN ('VALIDER', 'REFUSER') THEN
        RAISE EXCEPTION 'decision invalide (VALIDER/REFUSER requis)';
    END IF;

    -- Vérifier statut actuel
    SELECT statut INTO v_current_statut
    FROM "AttestationRC"
    WHERE etudiant_id = OLD.etudiant_id;

    IF v_current_statut IS NULL THEN
        RAISE EXCEPTION 'AttestationRC introuvable pour etudiant_id=%', OLD.etudiant_id;
    END IF;

    IF v_current_statut <> 'EN_ATTENTE' THEN
        RAISE EXCEPTION 'Action impossible: statut actuel=% (attendu EN_ATTENTE)', v_current_statut;
    END IF;

    -- Appliquer la décision
    IF NEW.decision = 'VALIDER' THEN
        UPDATE "AttestationRC"
        SET statut = 'VALIDE',
            date_validation = CURRENT_DATE
        WHERE etudiant_id = OLD.etudiant_id;
    ELSE
        UPDATE "AttestationRC"
        SET statut = 'REFUSE',
            date_validation = CURRENT_DATE
        WHERE etudiant_id = OLD.etudiant_id;
    END IF;

    -- Log optionnel dans JournalEvenement (si existe)
    BEGIN
        SELECT utilisateur_id INTO v_user_id
        FROM "Secretaire"
        WHERE secretaire_id = NEW.secretaire_id;

        INSERT INTO "JournalEvenement"(utilisateur_id, type, payload, created_at)
        VALUES (
                   v_user_id,
                   'MODIFICATION',
                   jsonb_build_object(
                           'action', 'VALIDATION_RC',
                           'etudiant_id', OLD.etudiant_id,
                           'decision', NEW.decision,
                           'motif_refus', COALESCE(NEW.motif_refus, '')
                   ),
                   NOW()
               );
    EXCEPTION WHEN undefined_table THEN
        -- JournalEvenement pas présent => ignore
        NULL;
    END;

    RETURN NEW;
END;
$$;

alter function trg_action_valider_attestation_rc_func() owner to m1user1_04;

create trigger trg_action_valider_attestation_rc_update
    instead of update
    on v_action_valider_attestation_rc
    for each row
execute procedure trg_action_valider_attestation_rc_func();

-- =====================================================
-- VUE ACTION : Mise à jour profil étudiant (CV + recherche)
-- =====================================================

create view v_action_update_profil_etudiant
            (utilisateur_id, en_recherche, cv_url) as
SELECT e.utilisateur_id,
       e.en_recherche,
       e.cv_url
FROM "Etudiant" e;

alter table v_action_update_profil_etudiant
    owner to m1user1_02;

grant select, update on v_action_update_profil_etudiant to role_etudiant;

create function trg_action_update_profil_etudiant_func() returns trigger
    language plpgsql
as
$$
BEGIN
    UPDATE "Etudiant"
    SET en_recherche = COALESCE(NEW.en_recherche, OLD.en_recherche),
        cv_url = CASE
            WHEN NEW.cv_url IS DISTINCT FROM OLD.cv_url THEN NEW.cv_url
            ELSE OLD.cv_url
        END
    WHERE utilisateur_id = OLD.utilisateur_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Etudiant introuvable pour utilisateur_id=%', OLD.utilisateur_id;
    END IF;

    RETURN NEW;
END;
$$;

alter function trg_action_update_profil_etudiant_func() owner to m1user1_02;

create trigger trg_action_update_profil_etudiant_update
    instead of update
    on v_action_update_profil_etudiant
    for each row
execute procedure trg_action_update_profil_etudiant_func();

