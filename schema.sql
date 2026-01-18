create type role_enum as enum ('ETUDIANT', 'ENTREPRISE', 'ENSEIGNANT', 'SECRETAIRE', 'ADMIN');

alter type role_enum owner to m1user1_02;

create type rc_statut_enum as enum ('EN_ATTENTE', 'VALIDE', 'REFUSE');

alter type rc_statut_enum owner to m1user1_02;

create type offre_type_enum as enum ('STAGE', 'ALTERNANCE', 'CDD', '');

alter type offre_type_enum owner to m1user1_02;

create type validation_statut_enum as enum ('BROUILLON', 'EN_ATTENTE', 'VALIDE', 'REFUSE');

alter type validation_statut_enum owner to m1user1_02;

create type cand_statut_enum as enum ('EN_ATTENTE', 'ACCEPTE', 'RETENU', 'REFUSE', 'ANNULE');

alter type cand_statut_enum owner to m1user1_02;

create type renoncement_type_enum as enum ('etudiant', 'systeme', 'entreprise');

alter type renoncement_type_enum owner to m1user1_02;

create type journal_type_enum as enum ('CONNEXION', 'CREATION', 'MODIFICATION', 'SUPPRESSION', 'ERREUR');

alter type journal_type_enum owner to m1user1_02;

create type notification_type_enum as enum ('OFFRE_SOUMISE', 'OFFRE_VALIDEE', 'OFFRE_REFUSEE', 'CANDIDATURE_RECUE', 'CANDIDATURE_ACCEPTEE', 'CANDIDATURE_REJETEE', 'AFFECTATION_VALIDEE', 'RC_VALIDEE', 'RC_REFUSEE', 'SYSTEME', 'RC_EXPIRATION_PROCHE');

alter type notification_type_enum owner to m1user1_02;

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
            on delete cascade,
    promo          integer
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
    en_conge       boolean default false,
    promo          integer not null
);

alter table "Secretaire"
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

create table "Notification"
(
    notification_id serial
        primary key,
    destinataire_id integer                                not null
        references "Utilisateur"
            on delete cascade,
    type            notification_type_enum                 not null,
    titre           varchar(100)                           not null,
    message         text                                   not null,
    lien            varchar(255),
    entite_type     varchar(50),
    entite_id       integer,
    lu              boolean                  default false not null,
    created_at      timestamp with time zone default now() not null
);

comment on table "Notification" is 'Notifications internes pour les utilisateurs';

comment on column "Notification".entite_type is 'Type d''entité liée : offre, candidature, attestation';

comment on column "Notification".entite_id is 'ID de l''entité liée pour navigation';

alter table "Notification"
    owner to m1user1_02;

create index idx_notification_destinataire
    on "Notification" (destinataire_id);

create index idx_notification_non_lues
    on "Notification" (destinataire_id, lu)
    where (lu = false);

create index idx_notification_created
    on "Notification" (created_at desc);

create table "GroupeEtudiant"
(
    groupe_id                  serial
        primary key,
    nom_groupe                 varchar(50) not null,
    annee_scolaire             integer     not null,
    enseignant_referent_id     integer     not null
        constraint fk_groupe_enseignant
            references "Enseignant",
    secretaire_gestionnaire_id integer     not null
        constraint fk_groupe_secretaire
            references "Secretaire"
);

alter table "GroupeEtudiant"
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
    en_recherche   boolean default false,
    profil_visible boolean default false,
    cv_url         text,
    promo          integer not null,
    groupe_id      integer
        constraint fk_etudiant_groupe
            references "GroupeEtudiant"
            on delete set null
);

alter table "Etudiant"
    owner to m1user1_02;

create index idx_etudiant_groupe
    on "Etudiant" (groupe_id);

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
    date_validation date,
    date_expiration date default make_date(((EXTRACT(year FROM CURRENT_DATE))::integer + 1), 1, 1)
);

alter table "AttestationRC"
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

grant select on v_offres_visibles_etudiant to role_secretaire;

grant select on v_offres_visibles_etudiant to role_enseignant;

grant select on v_offres_visibles_etudiant to role_etudiant;

grant select on v_offres_visibles_etudiant to role_entreprise;

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
             entreprise_ville, entreprise_site, nom_groupe, enseignant_referent_id, secretaire_gestionnaire_id)
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
       e.site_web           AS entreprise_site,
       ge.nom_groupe,
       ge.enseignant_referent_id,
       ge.secretaire_gestionnaire_id
FROM "Candidature" c
         JOIN "Etudiant" et ON c.etudiant_id = et.etudiant_id
         JOIN "Utilisateur" u ON et.utilisateur_id = u.id
         JOIN "Offre" o ON c.offre_id = o.id
         JOIN "Entreprise" e ON o.entreprise_id = e.entreprise_id
         LEFT JOIN "GroupeEtudiant" ge ON et.groupe_id = ge.groupe_id;

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

grant select on v_referentiel_legal to role_enseignant;

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

create view v_attestation_rc_etudiant
            (utilisateur_id, etudiant_id, statut, fichier_url, date_depot, date_validation, date_expiration,
             est_expiree, jours_restants)
as
SELECT u.id    AS utilisateur_id,
       e.etudiant_id,
       a.statut,
       a.fichier_url,
       a.date_depot,
       a.date_validation,
       CASE
           WHEN a.statut = 'VALIDE'::rc_statut_enum AND a.date_depot IS NOT NULL THEN (
               date_trunc('year'::text, a.date_depot::timestamp with time zone)::date + '1 year'::interval)::date
           ELSE NULL::date
           END AS date_expiration,
       CASE
           WHEN a.statut = 'VALIDE'::rc_statut_enum AND a.date_depot IS NOT NULL THEN
               (date_trunc('year'::text, a.date_depot::timestamp with time zone)::date + '1 year'::interval)::date <=
               CURRENT_DATE
           ELSE false
           END AS est_expiree,
       CASE
           WHEN a.statut = 'VALIDE'::rc_statut_enum AND a.date_depot IS NOT NULL THEN GREATEST(0,
                                                                                               (date_trunc('year'::text, a.date_depot::timestamp with time zone)::date +
                                                                                                '1 year'::interval)::date -
                                                                                               CURRENT_DATE)
           ELSE NULL::integer
           END AS jours_restants
FROM "Utilisateur" u
         JOIN "Etudiant" e ON e.utilisateur_id = u.id
         LEFT JOIN LATERAL ( SELECT a1.etudiant_id,
                                    a1.statut,
                                    a1.fichier_url,
                                    a1.date_depot,
                                    a1.date_validation,
                                    a1.date_expiration
                             FROM "AttestationRC" a1
                             WHERE a1.etudiant_id = e.etudiant_id
                             ORDER BY a1.date_depot DESC NULLS LAST, a1.date_validation DESC NULLS LAST
                             LIMIT 1) a ON true;

alter table v_attestation_rc_etudiant
    owner to m1user1_04;

grant select on v_attestation_rc_etudiant to role_etudiant;

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

grant delete, insert, select, update on v_action_modifier_referentiel_legal to role_enseignant;

create view v_action_update_profil_etudiant(utilisateur_id, en_recherche, cv_url) as
SELECT e.utilisateur_id,
       e.en_recherche,
       e.cv_url
FROM "Etudiant" e;

alter table v_action_update_profil_etudiant
    owner to m1user1_02;

grant select, update on v_action_update_profil_etudiant to role_etudiant;

create view v_mes_notifications
            (notification_id, type, titre, message, lien, entite_type, entite_id, lu, created_at, destinataire_id) as
SELECT n.notification_id,
       n.type,
       n.titre,
       n.message,
       n.lien,
       n.entite_type,
       n.entite_id,
       n.lu,
       n.created_at,
       n.destinataire_id
FROM "Notification" n
ORDER BY n.created_at DESC;

comment on view v_mes_notifications is 'Vue pour récupérer les notifications - filtrer par destinataire_id';

alter table v_mes_notifications
    owner to m1user1_02;

create view v_notifications_count(destinataire_id, non_lues, total) as
SELECT "Notification".destinataire_id,
       count(*) FILTER (WHERE "Notification".lu = false) AS non_lues,
       count(*)                                          AS total
FROM "Notification"
GROUP BY "Notification".destinataire_id;

comment on view v_notifications_count is 'Compteur de notifications par utilisateur';

alter table v_notifications_count
    owner to m1user1_02;

create view v_action_marquer_notification_lue(notification_id, destinataire_id, lu) as
SELECT "Notification".notification_id,
       "Notification".destinataire_id,
       "Notification".lu
FROM "Notification";

alter table v_action_marquer_notification_lue
    owner to m1user1_02;

create view v_auth_login(id, email, password_hash, role, nom, actif) as
SELECT u.id,
       u.email,
       u.password_hash,
       u.role,
       u.nom,
       u.actif
FROM "Utilisateur" u;

alter table v_auth_login
    owner to m1user1_04;

create view v_liste_enseignants(utilisateur_id, nom, email, enseignant_id) as
SELECT u.id AS utilisateur_id,
       u.nom,
       u.email,
       e.enseignant_id
FROM "Enseignant" e
         JOIN "Utilisateur" u ON u.id = e.utilisateur_id
WHERE u.actif = true;

alter table v_liste_enseignants
    owner to m1user1_04;

create view v_profil_etudiant
            (utilisateur_id, email, role, etudiant_id, nom, prenom, promo, formation, en_recherche, profil_visible,
             cv_url) as
SELECT u.id AS utilisateur_id,
       u.email,
       u.role,
       et.etudiant_id,
       et.nom,
       et.prenom,
       et.promo,
       et.formation,
       et.en_recherche,
       et.profil_visible,
       et.cv_url
FROM "Utilisateur" u
         JOIN "Etudiant" et ON u.id = et.utilisateur_id;

alter table v_profil_etudiant
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

create view v_attestations_rc_a_valider(etudiant_id, nom, prenom, fichier_url, date_depot, promo, statut) as
SELECT a.etudiant_id,
       e.nom,
       e.prenom,
       a.fichier_url,
       a.date_depot,
       e.promo,
       a.statut
FROM "AttestationRC" a
         JOIN "Etudiant" e ON e.etudiant_id = a.etudiant_id
WHERE a.statut = 'EN_ATTENTE'::rc_statut_enum
ORDER BY a.date_depot DESC;

alter table v_attestations_rc_a_valider
    owner to m1user1_04;

grant select on v_attestations_rc_a_valider to role_secretaire;

create view v_etudiants_par_secretaire
            (secretaire_id, utilisateur_id, email, role, etudiant_id, nom, prenom, formation, promo, en_recherche,
             profil_visible, cv_url)
as
SELECT s.secretaire_id,
       u.id AS utilisateur_id,
       u.email,
       u.role,
       e.etudiant_id,
       e.nom,
       e.prenom,
       e.formation,
       e.promo,
       e.en_recherche,
       e.profil_visible,
       e.cv_url
FROM "Secretaire" s
         JOIN "GroupeEtudiant" ge ON ge.secretaire_gestionnaire_id = s.secretaire_id
         JOIN "Etudiant" e ON e.groupe_id = ge.groupe_id
         JOIN "Utilisateur" u ON u.id = e.utilisateur_id
WHERE u.actif = true;

alter table v_etudiants_par_secretaire
    owner to m1user1_02;

grant select on v_etudiants_par_secretaire to secretaire;

create view v_action_creer_etudiant
            (secretaire_utilisateur_id, email, password_hash, nom, prenom, formation, promo, utilisateur_id_created,
             etudiant_id_created)
as
SELECT NULL::integer AS secretaire_utilisateur_id,
       NULL::text    AS email,
       NULL::text    AS password_hash,
       NULL::text    AS nom,
       NULL::text    AS prenom,
       NULL::text    AS formation,
       NULL::integer AS promo,
       NULL::integer AS utilisateur_id_created,
       NULL::integer AS etudiant_id_created;

alter table v_action_creer_etudiant
    owner to m1user1_03;

create view v_action_creer_affectation(candidature_id) as
SELECT c.id AS candidature_id
FROM "Candidature" c;

alter table v_action_creer_affectation
    owner to m1user1_02;

grant insert on v_action_creer_affectation to secretaire;

create view v_admin_stats
            (total_utilisateurs, total_etudiants, total_entreprises, total_offres_actives, total_groupes,
             total_affectations) as
SELECT (SELECT count(*) AS count
        FROM "Utilisateur"
        WHERE "Utilisateur".actif = true)                                   AS total_utilisateurs,
       (SELECT count(*) AS count
        FROM "Etudiant" e
                 JOIN "Utilisateur" u ON e.utilisateur_id = u.id
        WHERE u.actif = true)                                               AS total_etudiants,
       (SELECT count(*) AS count
        FROM "Entreprise" e
                 JOIN "Utilisateur" u ON e.utilisateur_id = u.id
        WHERE u.actif = true)                                               AS total_entreprises,
       (SELECT count(*) AS count
        FROM "Offre"
        WHERE "Offre".statut_validation = 'VALIDE'::validation_statut_enum) AS total_offres_actives,
       (SELECT count(*) AS count
        FROM "GroupeEtudiant")                                              AS total_groupes,
       (SELECT count(*) AS count
        FROM "Candidature"
        WHERE "Candidature".statut = 'RETENU'::cand_statut_enum)            AS total_affectations;

alter table v_admin_stats
    owner to m1user1_03;

grant select on v_admin_stats to role_admin;

create view v_admin_groupes
            (groupe_id, nom_groupe, annee_scolaire, enseignant_id, enseignant_email, enseignant_nom, secretaire_id,
             secretaire_email, secretaire_nom, nb_etudiants)
as
SELECT g.groupe_id,
       g.nom_groupe,
       g.annee_scolaire,
       e.enseignant_id,
       ue.email                       AS enseignant_email,
       ue.nom                         AS enseignant_nom,
       s.secretaire_id,
       us.email                       AS secretaire_email,
       us.nom                         AS secretaire_nom,
       count(DISTINCT et.etudiant_id) AS nb_etudiants
FROM "GroupeEtudiant" g
         LEFT JOIN "Enseignant" e ON g.enseignant_referent_id = e.enseignant_id
         LEFT JOIN "Utilisateur" ue ON e.utilisateur_id = ue.id
         LEFT JOIN "Secretaire" s ON g.secretaire_gestionnaire_id = s.secretaire_id
         LEFT JOIN "Utilisateur" us ON s.utilisateur_id = us.id
         LEFT JOIN "Etudiant" et ON et.groupe_id = g.groupe_id
GROUP BY g.groupe_id, g.nom_groupe, g.annee_scolaire, e.enseignant_id, ue.email, ue.nom, s.secretaire_id, us.email,
         us.nom;

alter table v_admin_groupes
    owner to m1user1_03;

grant select on v_admin_groupes to role_admin;

create view v_admin_enseignants(enseignant_id, utilisateur_id, email, nom, actif) as
SELECT e.enseignant_id,
       u.id AS utilisateur_id,
       u.email,
       u.nom,
       u.actif
FROM "Enseignant" e
         JOIN "Utilisateur" u ON e.utilisateur_id = u.id
WHERE u.actif = true;

alter table v_admin_enseignants
    owner to m1user1_03;

grant select on v_admin_enseignants to role_admin;

create view v_admin_secretaires(secretaire_id, utilisateur_id, email, nom, actif, en_conge) as
SELECT s.secretaire_id,
       u.id AS utilisateur_id,
       u.email,
       u.nom,
       u.actif,
       s.en_conge
FROM "Secretaire" s
         JOIN "Utilisateur" u ON s.utilisateur_id = u.id
WHERE u.actif = true;

alter table v_admin_secretaires
    owner to m1user1_03;

grant select on v_admin_secretaires to role_admin;

create view v_action_creer_groupe (nom_groupe, annee_scolaire, enseignant_id, secretaire_id, groupe_id_created) as
SELECT NULL::text    AS nom_groupe,
       NULL::integer AS annee_scolaire,
       NULL::integer AS enseignant_id,
       NULL::integer AS secretaire_id,
       NULL::integer AS groupe_id_created;

alter table v_action_creer_groupe
    owner to m1user1_03;

grant insert on v_action_creer_groupe to role_admin;

create view v_action_modifier_groupe(groupe_id, nom_groupe, annee_scolaire, enseignant_id, secretaire_id) as
SELECT g.groupe_id,
       g.nom_groupe,
       g.annee_scolaire,
       g.enseignant_referent_id     AS enseignant_id,
       g.secretaire_gestionnaire_id AS secretaire_id
FROM "GroupeEtudiant" g;

alter table v_action_modifier_groupe
    owner to m1user1_03;

grant update on v_action_modifier_groupe to role_admin;

create view v_action_supprimer_groupe(groupe_id, nom_groupe) as
SELECT g.groupe_id,
       g.nom_groupe
FROM "GroupeEtudiant" g;

alter table v_action_supprimer_groupe
    owner to m1user1_03;

grant delete on v_action_supprimer_groupe to role_admin;

create view v_action_creer_enseignant (email, password_hash, nom, utilisateur_id_created, enseignant_id_created) as
SELECT NULL::text    AS email,
       NULL::text    AS password_hash,
       NULL::text    AS nom,
       NULL::integer AS utilisateur_id_created,
       NULL::integer AS enseignant_id_created;

alter table v_action_creer_enseignant
    owner to m1user1_03;

grant insert on v_action_creer_enseignant to role_admin;

create view v_action_creer_secretaire (email, password_hash, nom, utilisateur_id_created, secretaire_id_created) as
SELECT NULL::text    AS email,
       NULL::text    AS password_hash,
       NULL::text    AS nom,
       NULL::integer AS utilisateur_id_created,
       NULL::integer AS secretaire_id_created;

alter table v_action_creer_secretaire
    owner to m1user1_03;

grant insert on v_action_creer_secretaire to role_admin;

create view v_candidatures_a_valider
            (candidature_id, nom_etudiant, prenom_etudiant, titre_offre, nom_entreprise, date_debut_offre, nom_groupe,
             enseignant_referent_id, secretaire_gestionnaire_id)
as
SELECT c.id             AS candidature_id,
       et.nom           AS nom_etudiant,
       et.prenom        AS prenom_etudiant,
       o.titre          AS titre_offre,
       e.raison_sociale AS nom_entreprise,
       o.date_debut     AS date_debut_offre,
       ge.nom_groupe,
       ge.enseignant_referent_id,
       ge.secretaire_gestionnaire_id
FROM "Candidature" c
         JOIN "Etudiant" et ON c.etudiant_id = et.etudiant_id
         JOIN "Utilisateur" u ON et.utilisateur_id = u.id
         JOIN "Offre" o ON c.offre_id = o.id
         JOIN "Entreprise" e ON o.entreprise_id = e.entreprise_id
         LEFT JOIN "GroupeEtudiant" ge ON et.groupe_id = ge.groupe_id
         LEFT JOIN "Affectation" a ON c.id = a.candidature_id
WHERE c.statut = 'RETENU'::cand_statut_enum
  AND a.candidature_id IS NULL;

alter table v_candidatures_a_valider
    owner to m1user1_02;

create view v_attestations_rc_expirees_secretaire
            (utilisateur_id, etudiant_id, nom, prenom, email, date_expiration, jours_depuis_expiration) as
SELECT p.utilisateur_id,
       p.etudiant_id,
       p.nom,
       p.prenom,
       p.email,
       a.date_expiration,
       CURRENT_DATE - a.date_expiration AS jours_depuis_expiration
FROM v_attestation_rc_etudiant a
         JOIN v_profil_etudiant p ON p.etudiant_id = a.etudiant_id
WHERE a.statut = 'VALIDE'::rc_statut_enum
  AND a.est_expiree = true
ORDER BY (CURRENT_DATE - a.date_expiration) DESC;

alter table v_attestations_rc_expirees_secretaire
    owner to m1user1_04;

grant select on v_attestations_rc_expirees_secretaire to role_secretaire;

create view v_action_renoncer_candidature(candidature_id, type_acteur, justification) as
SELECT c.id                    AS candidature_id,
       NULL::character varying AS type_acteur,
       NULL::text              AS justification
FROM "Candidature" c;

alter table v_action_renoncer_candidature
    owner to m1user1_02;

create view v_action_refuser_candidature(candidature_id) as
SELECT "Candidature".id AS candidature_id
FROM "Candidature";

alter table v_action_refuser_candidature
    owner to m1user1_02;

create view v_secretaire_autorise_by_user(secretaire_id, utilisateur_id) as
SELECT s.secretaire_id,
       s.utilisateur_id
FROM "Secretaire" s
WHERE s.en_conge = false
UNION ALL
SELECT s.secretaire_id,
       ens.utilisateur_id
FROM "Secretaire" s
         JOIN "GroupeEtudiant" ge ON ge.secretaire_gestionnaire_id = s.secretaire_id
         JOIN "Enseignant" ens ON ens.enseignant_id = ge.enseignant_referent_id
WHERE s.en_conge = true;

alter table v_secretaire_autorise_by_user
    owner to m1user1_03;

create view v_action_toggle_conge_secretaire(secretaire_id, en_conge) as
SELECT NULL::integer AS secretaire_id,
       NULL::boolean AS en_conge;

alter table v_action_toggle_conge_secretaire
    owner to m1user1_03;

create view v_remplacant_secretaire
            (secretaire_id, secretaire_user_id, remplacant_user_id, remplacant_nom, remplacant_email, groupe_id,
             nom_groupe) as
SELECT s.secretaire_id,
       s.utilisateur_id   AS secretaire_user_id,
       ens.utilisateur_id AS remplacant_user_id,
       u.nom              AS remplacant_nom,
       u.email            AS remplacant_email,
       ge.groupe_id,
       ge.nom_groupe
FROM "Secretaire" s
         JOIN "GroupeEtudiant" ge ON ge.secretaire_gestionnaire_id = s.secretaire_id
         JOIN "Enseignant" ens ON ens.enseignant_id = ge.enseignant_referent_id
         JOIN "Utilisateur" u ON u.id = ens.utilisateur_id;

alter table v_remplacant_secretaire
    owner to m1user1_03;

create function trg_action_postuler_func() returns trigger
    language plpgsql
as
$$
DECLARE
    v_statut_offre validation_statut_enum;
    v_user_id int;
    v_candidature_id int;
BEGIN
    SELECT statut_validation INTO v_statut_offre
    FROM "Offre" WHERE id = NEW.offre_id;

    IF v_statut_offre IS DISTINCT FROM 'VALIDE' THEN
        RAISE EXCEPTION 'Impossible de postuler : Cette offre n''est pas disponible.';
    END IF;

-- Dans le trigger trg_creer_candidature, ajouter cette vérification :
    IF EXISTS (
        SELECT 1 FROM affectation a
                          JOIN offre o_existant ON o_existant.id = a.offre_id
                          JOIN offre o_nouveau ON o_nouveau.id = NEW.offre_id
        WHERE a.etudiant_id = NEW.etudiant_id
          AND (o_existant.date_debut, o_existant.date_fin) OVERLAPS (o_nouveau.date_debut, o_nouveau.date_fin)
    ) THEN
        RAISE EXCEPTION 'Vous avez déjà un stage validé sur cette période';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM "Candidature"
        WHERE offre_id = NEW.offre_id
          AND etudiant_id = NEW.etudiant_id
          AND statut != 'ANNULE'
    ) THEN
        RAISE EXCEPTION 'Vous avez déjà une candidature pour cette offre.';
    END IF;

    INSERT INTO "Candidature" (offre_id, etudiant_id, source, statut, date_candidature)
    VALUES (NEW.offre_id, NEW.etudiant_id, NEW.source, 'EN_ATTENTE', CURRENT_DATE)
    RETURNING id INTO v_candidature_id;

    SELECT utilisateur_id INTO v_user_id
    FROM "Etudiant"
    WHERE etudiant_id = NEW.etudiant_id;

    PERFORM public.f_journal_log(
            v_user_id,
            'CREATION',
            jsonb_build_object(
                    'action','POSTULER_OFFRE',
                    'candidature_id', v_candidature_id,
                    'offre_id', NEW.offre_id,
                    'etudiant_id', NEW.etudiant_id,
                    'source', COALESCE(NEW.source,'')
            )::text
            );

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
DECLARE
    v_user_id int;
BEGIN
    INSERT INTO "Offre" (
        entreprise_id, type, titre, description, competences,
        localisation_pays, localisation_ville, duree_mois, remuneration,
        date_debut, date_expiration,
        statut_validation, date_soumission, date_validation
    )
    VALUES (
               NEW.entreprise_id, NEW.type, NEW.titre, NEW.description, NEW.competences,
               NEW.localisation_pays, NEW.localisation_ville, NEW.duree_mois, NEW.remuneration,
               NEW.date_debut, NEW.date_expiration,
               'EN_ATTENTE', CURRENT_DATE, NULL
           )
    RETURNING id INTO NEW.id;

    SELECT utilisateur_id INTO v_user_id
    FROM "Entreprise"
    WHERE entreprise_id = NEW.entreprise_id;

    PERFORM public.f_journal_log(
            v_user_id,
            'CREATION',
            jsonb_build_object(
                    'action','CREER_OFFRE',
                    'offre_id', NEW.id,
                    'entreprise_id', NEW.entreprise_id,
                    'titre', NEW.titre,
                    'type', NEW.type
            )::text
            );

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
$$DECLARE
    v_statut_actuel cand_statut_enum;
    v_user_id int;
BEGIN
    -- 1. Récupération du statut actuel
    SELECT statut INTO v_statut_actuel
    FROM "Candidature" WHERE id = OLD.candidature_id;

    -- 2. MODIFICATION ICI : On vérifie si le statut n'est PAS dans la liste autorisée
    -- Si le statut est différent de EN_ATTENTE ET différent de RETENU, on bloque.
    IF v_statut_actuel NOT IN ('EN_ATTENTE', 'RETENU') THEN
        RAISE EXCEPTION 'Impossible d''annuler cette candidature. Statut actuel : % (Seuls EN_ATTENTE et RETENU sont annulables)', v_statut_actuel;
    END IF;

    -- 3. Mise à jour du statut
    UPDATE "Candidature"
    SET statut = 'ANNULE'
    WHERE id = OLD.candidature_id;

    -- 4. Récupération de l'user ID pour les logs
    SELECT utilisateur_id INTO v_user_id
    FROM "Etudiant"
    WHERE etudiant_id = OLD.etudiant_id;

    -- 5. Logging
    PERFORM public.f_journal_log(
            v_user_id,
            'MODIFICATION',
            jsonb_build_object(
                    'action','ANNULER_CANDIDATURE',
                    'candidature_id', OLD.candidature_id,
                    'etudiant_id', OLD.etudiant_id,
                    'old_statut', v_statut_actuel,
                    'new_statut', 'ANNULE'
            )::text
            );

    RETURN NEW;
END;$$;

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
$$DECLARE
    v_etudiant_id UUID;
    v_offre_id UUID;
    v_statut_candidature VARCHAR;
    v_enseignant_ref_id INTEGER;
    v_date_debut DATE;
    v_duree_mois INTEGER;
    v_date_fin_estimee DATE;
BEGIN
    -- 1. Récupération des infos de la candidature et de l'offre
    SELECT
        c.etudiant_id,
        c.offre_id,
        c.statut,
        o.date_debut,
        o.duree_mois
    INTO
        v_etudiant_id,
        v_offre_id,
        v_statut_candidature,
        v_date_debut,
        v_duree_mois
    FROM public."Candidature" c
             JOIN public."Offre" o ON c.offre_id = o.id
    WHERE c.id = NEW.candidature_id;

    -- 2. Sécurités (Existe ? Déjà traité ? Doublon ?)
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Candidature introuvable (ID: %)', NEW.candidature_id;
    END IF;

    -- On vérifie qu'on ne valide pas une candidature déjà traitée (ACCEPTE ou autre)
    -- On accepte 'RETENU' (validation entreprise) ou 'EN_ATTENTE' si le process l'autorise
    IF v_statut_candidature = 'ACCEPTE' THEN
        RAISE NOTICE 'Cette candidature est déjà acceptée.';
        RETURN NEW;
    END IF;

    -- Vérification doublon dans Affectation
    PERFORM 1 FROM public."Affectation" WHERE candidature_id = NEW.candidature_id;
    IF FOUND THEN
        RAISE EXCEPTION 'Une affectation existe déjà pour cette candidature.';
    END IF;

    -- 3. Récupération automatique du Professeur Référent (via le Groupe)
    SELECT g.enseignant_referent_id
    INTO v_enseignant_ref_id
    FROM public."Etudiant" e
             LEFT JOIN public."GroupeEtudiant" g ON e.groupe_id = g.groupe_id
    WHERE e.etudiant_id = v_etudiant_id;

    -- 4. Calcul de la date de fin
    IF v_date_debut IS NOT NULL AND v_duree_mois IS NOT NULL THEN
        v_date_fin_estimee := v_date_debut + (v_duree_mois * INTERVAL '1 month');
    ELSE
        v_date_fin_estimee := NULL;
    END IF;

    -- ============================================================
    -- ACTION PRINCIPALE 1 : Création de l'Affectation
    -- ============================================================
    INSERT INTO public."Affectation" (
        candidature_id,
        etudiant_id,
        offre_id,
        enseignant_id,
        date_debut,
        date_fin,
        date_validation -- Correspond à ton champ date_creation/validation
    ) VALUES (
                 NEW.candidature_id,
                 v_etudiant_id,
                 v_offre_id,
                 v_enseignant_ref_id,
                 v_date_debut,
                 v_date_fin_estimee,
                 CURRENT_DATE
             );

    -- ============================================================
    -- ACTION PRINCIPALE 2 : Mise à jour du statut Candidature (NOUVEAU)
    -- ============================================================
    UPDATE public."Candidature"
    SET statut = 'ACCEPTE' -- On utilise la valeur de ton Enum
    WHERE id = NEW.candidature_id;

    RETURN NEW;
END;$$;

alter function trg_ens_valider_affectation_func() owner to m1user1_02;

create function trg_action_deposer_attestation_rc_func() returns trigger
    language plpgsql
as
$$
DECLARE
    v_statut_existant rc_statut_enum;
    v_user_id int;
BEGIN
    SELECT utilisateur_id INTO v_user_id
    FROM "Etudiant"
    WHERE etudiant_id = NEW.etudiant_id;

    SELECT statut INTO v_statut_existant
    FROM "AttestationRC"
    WHERE etudiant_id = NEW.etudiant_id;

    IF NOT FOUND THEN
        INSERT INTO "AttestationRC"(etudiant_id, statut, fichier_url, date_depot, date_validation)
        VALUES (NEW.etudiant_id, 'EN_ATTENTE', NEW.fichier_url, CURRENT_DATE, NULL);

        PERFORM public.f_journal_log(
                v_user_id,
                'CREATION',
                jsonb_build_object(
                        'action','DEPOSER_ATTESTATION_RC',
                        'etudiant_id', NEW.etudiant_id,
                        'statut','EN_ATTENTE'
                )::text
                );

        RETURN NEW;
    END IF;

    IF v_statut_existant = 'REFUSE' THEN
        UPDATE "AttestationRC"
        SET fichier_url = NEW.fichier_url,
            statut = 'EN_ATTENTE',
            date_depot = CURRENT_DATE,
            date_validation = NULL
        WHERE etudiant_id = NEW.etudiant_id;

        PERFORM public.f_journal_log(
                v_user_id,
                'MODIFICATION',
                jsonb_build_object(
                        'action','REDEPOT_ATTESTATION_RC',
                        'etudiant_id', NEW.etudiant_id,
                        'old_statut', v_statut_existant,
                        'new_statut','EN_ATTENTE'
                )::text
                );

        RETURN NEW;
    END IF;

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
DECLARE
    v_old_statut cand_statut_enum;
    v_user_id int;
BEGIN
    SELECT statut INTO v_old_statut
    FROM "Candidature"
    WHERE id = NEW.candidature_id;

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

    SELECT utilisateur_id INTO v_user_id
    FROM "Entreprise"
    WHERE entreprise_id = NEW.entreprise_id;

    PERFORM public.f_journal_log(
            v_user_id,
            'MODIFICATION',
            jsonb_build_object(
                    'action','ENTREPRISE_DECIDER_CANDIDATURE',
                    'candidature_id', NEW.candidature_id,
                    'entreprise_id', NEW.entreprise_id,
                    'old_statut', v_old_statut,
                    'new_statut', NEW.statut
            )::text
            );

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
    IF NEW.decision IS NULL OR NEW.decision NOT IN ('VALIDER', 'REFUSER') THEN
        RAISE EXCEPTION 'decision invalide (VALIDER/REFUSER requis)';
    END IF;

    SELECT statut INTO v_current_statut
    FROM "AttestationRC"
    WHERE etudiant_id = OLD.etudiant_id;

    IF v_current_statut IS NULL THEN
        RAISE EXCEPTION 'AttestationRC introuvable pour etudiant_id=%', OLD.etudiant_id;
    END IF;

    IF v_current_statut <> 'EN_ATTENTE' THEN
        RAISE EXCEPTION 'Action impossible: statut actuel=% (attendu EN_ATTENTE)', v_current_statut;
    END IF;

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

    SELECT utilisateur_id INTO v_user_id
    FROM "Secretaire"
    WHERE secretaire_id = NEW.secretaire_id;

    PERFORM public.f_journal_log(
            v_user_id,
            'MODIFICATION',
            jsonb_build_object(
                    'action','VALIDATION_RC',
                    'etudiant_id', OLD.etudiant_id,
                    'decision', NEW.decision,
                    'motif_refus', COALESCE(NEW.motif_refus,'')
            )::text
            );

    RETURN NEW;
END;
$$;

alter function trg_action_valider_attestation_rc_func() owner to m1user1_04;

create trigger trg_action_valider_attestation_rc_update
    instead of update
    on v_action_valider_attestation_rc
    for each row
execute procedure trg_action_valider_attestation_rc_func();

create function trg_action_creer_etudiant_func() returns trigger
    language plpgsql
as
$$
DECLARE
    v_user_id int;
    v_etudiant_id int;
BEGIN
    -- 1) Vérifier que l'appelant est bien secrétaire
    IF NOT EXISTS (
        SELECT 1
        FROM public.v_secretaire_autorise_by_user s
        WHERE s.utilisateur_id = NEW.secretaire_utilisateur_id
    ) THEN
        RAISE EXCEPTION 'Accès interdit: utilisateur % n''est pas secrétaire', NEW.secretaire_utilisateur_id;
    END IF;

    -- 2) Vérifier email unique
    IF EXISTS (
        SELECT 1
        FROM "Utilisateur" u
        WHERE u.email = NEW.email
    ) THEN
        RAISE EXCEPTION 'Email déjà utilisé: %', NEW.email;
    END IF;

    -- 3) Insérer Utilisateur (password_hash fourni par Node, pas de mot de passe en clair)
    INSERT INTO "Utilisateur"(email, password_hash, role, actif, nom)
    VALUES (NEW.email, NEW.password_hash, 'ETUDIANT', true, NEW.nom)
    RETURNING id INTO v_user_id;

    -- 4) Insérer Etudiant
    INSERT INTO "Etudiant"(utilisateur_id, nom, prenom, formation, promo, en_recherche, profil_visible)
    VALUES (v_user_id, NEW.nom, NEW.prenom, NEW.formation, NEW.promo, false, false)
    RETURNING etudiant_id INTO v_etudiant_id;

    -- 5) Retour "propre"
    NEW.utilisateur_id_created := v_user_id;
    NEW.etudiant_id_created := v_etudiant_id;

    RETURN NEW;
END;
$$;

alter function trg_action_creer_etudiant_func() owner to m1user1_04;

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

    PERFORM public.f_journal_log(
            OLD.utilisateur_id,
            'MODIFICATION',
            jsonb_build_object(
                    'action','UPDATE_PROFIL_ETUDIANT',
                    'utilisateur_id', OLD.utilisateur_id,
                    'en_recherche', COALESCE(NEW.en_recherche, OLD.en_recherche),
                    'cv_url', CASE
                                  WHEN NEW.cv_url IS DISTINCT FROM OLD.cv_url THEN NEW.cv_url
                                  ELSE OLD.cv_url
                        END
            )::text
            );

    RETURN NEW;
END;
$$;

alter function trg_action_update_profil_etudiant_func() owner to m1user1_02;

create trigger trg_action_update_profil_etudiant_update
    instead of update
    on v_action_update_profil_etudiant
    for each row
execute procedure trg_action_update_profil_etudiant_func();

create function trg_marquer_notification_lue() returns trigger
    language plpgsql
as
$$
BEGIN
    -- Sécurité : on ne peut marquer que ses propres notifications
    UPDATE "Notification"
    SET lu = TRUE
    WHERE notification_id = NEW.notification_id
      AND destinataire_id = NEW.destinataire_id;

    RETURN NEW;
END;
$$;

alter function trg_marquer_notification_lue() owner to m1user1_03;

create trigger trg_action_marquer_lue
    instead of update
    on v_action_marquer_notification_lue
    for each row
execute procedure trg_marquer_notification_lue();

create function trg_action_marquer_notification_lue_func() returns trigger
    language plpgsql
as
$$
BEGIN
    UPDATE "Notification"
    SET lu = NEW.lu
    WHERE notification_id = OLD.notification_id
      AND destinataire_id = OLD.destinataire_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Notification introuvable ou accès non autorisé (id=%, user=%)',
            OLD.notification_id, OLD.destinataire_id;
    END IF;

    RETURN NEW;
END;
$$;

alter function trg_action_marquer_notification_lue_func() owner to m1user1_03;

create trigger trg_action_marquer_notification_lue_update
    instead of update
    on v_action_marquer_notification_lue
    for each row
execute procedure trg_action_marquer_notification_lue_func();

create function creer_notification(p_destinataire_id integer, p_type notification_type_enum, p_titre text, p_message text, p_lien text DEFAULT NULL::text, p_entite_type text DEFAULT NULL::text, p_entite_id integer DEFAULT NULL::integer) returns integer
    language plpgsql
as
$$
DECLARE
    v_notification_id integer;
BEGIN
    INSERT INTO "Notification" (destinataire_id, type, titre, message, lien, entite_type, entite_id)
    VALUES (p_destinataire_id, p_type, p_titre, p_message, p_lien, p_entite_type, p_entite_id)
    RETURNING notification_id INTO v_notification_id;

    RETURN v_notification_id;
END;
$$;

alter function creer_notification(integer, notification_type_enum, text, text, text, text, integer) owner to m1user1_03;

create function trg_notify_offre_soumise() returns trigger
    language plpgsql
as
$$
DECLARE
    v_enseignant_user_id INTEGER;
    v_entreprise_nom VARCHAR(255);
BEGIN
    SELECT e.raison_sociale INTO v_entreprise_nom
    FROM "Entreprise" e
    WHERE e.entreprise_id = NEW.entreprise_id;

    FOR v_enseignant_user_id IN
        SELECT u.id FROM "Utilisateur" u WHERE u.role = 'ENSEIGNANT'
        LOOP
            PERFORM fn_creer_notification(
                    v_enseignant_user_id,
                    'OFFRE_SOUMISE'::notification_type_enum,
                    'Nouvelle offre à valider',
                    format('L''entreprise %s a soumis l''offre "%s"',
                           COALESCE(v_entreprise_nom, 'Inconnue'),
                           COALESCE(NEW.titre, 'Sans titre')),
                    format('/dashboard/enseignant?offre=%s', NEW.id),
                    'offre',
                    NEW.id
                    );
        END LOOP;
    RETURN NEW;
END;
$$;

alter function trg_notify_offre_soumise() owner to m1user1_03;

create trigger trg_offre_soumise_notification
    after insert
    on "Offre"
    for each row
    when (new.statut_validation = 'EN_ATTENTE'::validation_statut_enum)
execute procedure trg_notify_offre_soumise();

create function trg_notify_offre_decision() returns trigger
    language plpgsql
as
$$
DECLARE
    v_entreprise_user_id INTEGER;
    v_type notification_type_enum;
    v_titre VARCHAR(100);
    v_message TEXT;
BEGIN
    IF OLD.statut_validation IS NOT DISTINCT FROM NEW.statut_validation THEN
        RETURN NEW;
    END IF;

    SELECT e.utilisateur_id INTO v_entreprise_user_id
    FROM "Entreprise" e
    WHERE e.entreprise_id = NEW.entreprise_id;

    IF v_entreprise_user_id IS NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.statut_validation = 'VALIDE' THEN
        v_type := 'OFFRE_VALIDEE';
        v_titre := 'Offre validée';
        v_message := format('Votre offre "%s" a été validée et est maintenant visible par les étudiants.',
                            COALESCE(NEW.titre, 'Sans titre'));
    ELSIF NEW.statut_validation = 'REFUSE' THEN
        v_type := 'OFFRE_REFUSEE';
        v_titre := 'Offre refusée';
        v_message := format('Votre offre "%s" a été refusée. Consultez les détails pour connaître le motif.',
                            COALESCE(NEW.titre, 'Sans titre'));
    ELSE
        RETURN NEW;
    END IF;

    PERFORM fn_creer_notification(
            v_entreprise_user_id,
            v_type,
            v_titre,
            v_message,
            format('/dashboard/entreprise?offre=%s', NEW.id),
            'offre',
            NEW.id
            );
    RETURN NEW;
END;
$$;

alter function trg_notify_offre_decision() owner to m1user1_03;

create trigger trg_offre_decision_notification
    after update
        of statut_validation
    on "Offre"
    for each row
execute procedure trg_notify_offre_decision();

create function trg_notify_nouvelle_candidature() returns trigger
    language plpgsql
as
$$
DECLARE
    v_entreprise_user_id INTEGER;
    v_etudiant_nom VARCHAR(255);
    v_offre_titre VARCHAR(255);
BEGIN
    SELECT CONCAT(e.prenom, ' ', e.nom) INTO v_etudiant_nom
    FROM "Etudiant" e
    WHERE e.etudiant_id = NEW.etudiant_id;

    SELECT o.titre, ent.utilisateur_id
    INTO v_offre_titre, v_entreprise_user_id
    FROM "Offre" o
             JOIN "Entreprise" ent ON ent.entreprise_id = o.entreprise_id
    WHERE o.id = NEW.offre_id;

    IF v_entreprise_user_id IS NULL THEN
        RETURN NEW;
    END IF;

    PERFORM fn_creer_notification(
            v_entreprise_user_id,
            'CANDIDATURE_RECUE'::notification_type_enum,
            'Nouvelle candidature reçue',
            format('%s a candidaté à votre offre "%s"',
                   COALESCE(v_etudiant_nom, 'Un étudiant'),
                   COALESCE(v_offre_titre, 'votre offre')),
            format('/dashboard/entreprise?candidature=%s', NEW.id),
            'candidature',
            NEW.id
            );
    RETURN NEW;
END;
$$;

alter function trg_notify_nouvelle_candidature() owner to m1user1_03;

create trigger trg_candidature_notification
    after insert
    on "Candidature"
    for each row
execute procedure trg_notify_nouvelle_candidature();

create function trg_notify_candidature_decision() returns trigger
    language plpgsql
as
$$DECLARE
    v_etudiant_user_id INTEGER;
    v_offre_titre VARCHAR(255);
    v_entreprise_nom VARCHAR(255);
    v_type notification_type_enum; -- Vérifie que ce type existe bien
    v_titre VARCHAR(100);
    v_message TEXT;
BEGIN
    -- 1. Si le statut n'a pas changé, on ne fait rien
    IF OLD.statut IS NOT DISTINCT FROM NEW.statut THEN
        RETURN NEW;
    END IF;

    -- 2. Récupération de l'ID utilisateur de l'étudiant
    SELECT e.utilisateur_id INTO v_etudiant_user_id
    FROM public."Etudiant" e
    WHERE e.etudiant_id = NEW.etudiant_id;

    -- 3. Récupération des infos Offre/Entreprise
    SELECT o.titre, ent.raison_sociale
    INTO v_offre_titre, v_entreprise_nom
    FROM public."Offre" o
             JOIN public."Entreprise" ent ON ent.entreprise_id = o.entreprise_id
    WHERE o.id = NEW.offre_id;

    -- Sécurité : Si pas d'étudiant trouvé (cas rare), on sort
    IF v_etudiant_user_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- 4. Définition du message selon le NOUVEAU statut
    IF NEW.statut = 'RETENU' THEN
        v_type := 'CANDIDATURE_ACCEPTEE';
        v_titre := 'Candidature retenue';
        v_message := format('%s a retenu votre candidature pour le poste "%s" !',
                            COALESCE(v_entreprise_nom, 'Une entreprise'),
                            COALESCE(v_offre_titre, 'l''offre'));

        -- NOTE : J'ai supprimé le bloc 'ENTRETIEN' qui faisait planter le script
        -- Si tu as un nouveau statut (ex: 'ACCEPTE'), tu peux l'ajouter ici.

    ELSIF NEW.statut = 'REFUSE' THEN
        v_type := 'CANDIDATURE_REJETEE';
        v_titre := 'Candidature non retenue';
        v_message := format('Votre candidature pour "%s" chez %s n''a pas été retenue.',
                            COALESCE(v_offre_titre, 'l''offre'),
                            COALESCE(v_entreprise_nom, 'l''entreprise'));
    ELSE
        -- Pour les autres statuts (EN_ATTENTE, ANNULE, etc.), on n'envoie pas de notif
        RETURN NEW;
    END IF;

    -- 5. Appel de la fonction de création de notif
    PERFORM public.fn_creer_notification(
            v_etudiant_user_id,
            v_type,
            v_titre,
            v_message,
            '/candidatures', -- Lien vers la page
            'candidature',   -- Type d'entité liée
            NEW.id           -- ID de l'entité
            );

    RETURN NEW;
END;$$;

alter function trg_notify_candidature_decision() owner to m1user1_03;

create trigger trg_candidature_decision_notification
    after update
        of statut
    on "Candidature"
    for each row
execute procedure trg_notify_candidature_decision();

create function trg_notify_attestation_rc() returns trigger
    language plpgsql
as
$$
DECLARE
    v_etudiant_user_id INTEGER;
    v_type notification_type_enum;
    v_titre VARCHAR(100);
    v_message TEXT;
BEGIN
    IF OLD.statut IS NOT DISTINCT FROM NEW.statut THEN
        RETURN NEW;
    END IF;

    SELECT e.utilisateur_id INTO v_etudiant_user_id
    FROM "Etudiant" e
    WHERE e.etudiant_id = NEW.etudiant_id;

    IF v_etudiant_user_id IS NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.statut = 'VALIDE' THEN
        v_type := 'RC_VALIDEE';
        v_titre := 'Attestation RC validée';
        v_message := 'Votre attestation de responsabilité civile a été validée. Vous pouvez maintenant candidater aux offres.';
    ELSIF NEW.statut = 'REFUSE' THEN
        v_type := 'RC_REFUSEE';
        v_titre := 'Attestation RC refusée';
        v_message := 'Votre attestation de responsabilité civile a été refusée. Veuillez en déposer une nouvelle conforme.';
    ELSE
        RETURN NEW;
    END IF;

    PERFORM fn_creer_notification(
            v_etudiant_user_id,
            v_type,
            v_titre,
            v_message,
            '/profile#attestation',
            'attestation',
            NEW.etudiant_id
            );
    RETURN NEW;
END;
$$;

alter function trg_notify_attestation_rc() owner to m1user1_03;

create trigger trg_attestation_rc_notification
    after update
        of statut
    on "AttestationRC"
    for each row
execute procedure trg_notify_attestation_rc();

create function fn_creer_notification(p_destinataire_id integer, p_type notification_type_enum, p_titre character varying, p_message text, p_lien character varying DEFAULT NULL::character varying, p_entite_type character varying DEFAULT NULL::character varying, p_entite_id integer DEFAULT NULL::integer) returns integer
    language plpgsql
as
$$
DECLARE
    v_notification_id INTEGER;
BEGIN
    INSERT INTO "Notification" (
        destinataire_id, type, titre, message, lien, entite_type, entite_id
    ) VALUES (
                 p_destinataire_id, p_type, p_titre, p_message, p_lien, p_entite_type, p_entite_id
             ) RETURNING notification_id INTO v_notification_id;

    RETURN v_notification_id;
END;
$$;

alter function fn_creer_notification(integer, notification_type_enum, varchar, text, varchar, varchar, integer) owner to m1user1_03;

create function notify_rc_expirations_proches(jours_avant integer DEFAULT 30)
    returns TABLE(etudiant_id integer, notification_id integer)
    language plpgsql
as
$$
DECLARE
    v_row RECORD;
    v_notif_id integer;
BEGIN
    -- Parcourir toutes les attestations RC validées qui expirent dans les X prochains jours
    -- et qui n'ont pas encore reçu de notification d'expiration récente (dans les 7 derniers jours)
    FOR v_row IN
        SELECT
            e.etudiant_id,
            e.utilisateur_id,
            a.date_expiration,
            (a.date_expiration - CURRENT_DATE) AS jours_restants
        FROM "AttestationRC" a
                 JOIN "Etudiant" e ON e.etudiant_id = a.etudiant_id
        WHERE a.statut = 'VALIDE'
          AND a.date_expiration > CURRENT_DATE
          AND a.date_expiration <= CURRENT_DATE + jours_avant
          AND NOT EXISTS (
            SELECT 1 FROM "Notification" n
            WHERE n.destinataire_id = e.utilisateur_id
              AND n.type = 'RC_EXPIRATION_PROCHE'
              AND n.created_at > CURRENT_DATE - INTERVAL '7 days'
        )
        LOOP
            -- Créer la notification
            INSERT INTO "Notification" (destinataire_id, type, titre, message, lien, entite_type, entite_id)
            VALUES (
                       v_row.utilisateur_id,
                       'RC_EXPIRATION_PROCHE',
                       'Attestation RC bientôt expirée',
                       'Votre attestation de Responsabilité Civile expire dans ' || v_row.jours_restants || ' jour(s). Pensez à la renouveler.',
                       '/attestation-rc',
                       'attestation_rc',
                       v_row.etudiant_id
                   )
            RETURNING id INTO v_notif_id;

            etudiant_id := v_row.etudiant_id;
            notification_id := v_notif_id;
            RETURN NEXT;
        END LOOP;
END;
$$;

alter function notify_rc_expirations_proches(integer) owner to m1user1_03;

create function fn_creer_etudiant() returns trigger
    security definer
    language plpgsql
as
$$
DECLARE
    v_secretaire_id INTEGER;
    v_groupe_id INTEGER;
    v_utilisateur_id INTEGER;
    v_etudiant_id INTEGER;
BEGIN
    -- 1. Vérifier que l'utilisateur est bien une secrétaire
    SELECT s.secretaire_id INTO v_secretaire_id
    FROM public."Secretaire" s
             JOIN public."Utilisateur" u ON u.id = s.utilisateur_id
    WHERE u.id = NEW.secretaire_utilisateur_id
      AND u.role = 'SECRETAIRE'
      AND u.actif = true;

    IF v_secretaire_id IS NULL THEN
        RAISE EXCEPTION 'Accès interdit : utilisateur non secrétaire ou inactif';
    END IF;

    -- 2. Récupérer le groupe_id de la secrétaire
    SELECT ge.groupe_id INTO v_groupe_id
    FROM public."GroupeEtudiant" ge
    WHERE ge.secretaire_gestionnaire_id = v_secretaire_id
    LIMIT 1;

    IF v_groupe_id IS NULL THEN
        RAISE EXCEPTION 'Aucun groupe assigné à cette secrétaire';
    END IF;

    -- 3. Vérifier unicité email
    IF EXISTS (SELECT 1 FROM public."Utilisateur" WHERE email = NEW.email) THEN
        RAISE EXCEPTION 'Email déjà utilisé : %', NEW.email;
    END IF;

    -- 4. Créer l'utilisateur
    INSERT INTO public."Utilisateur" (email, password_hash, role, actif)
    VALUES (NEW.email, NEW.password_hash, 'ETUDIANT', true)
    RETURNING id INTO v_utilisateur_id;

    -- 5. Créer l'étudiant avec groupe_id
    INSERT INTO public."Etudiant" (utilisateur_id, nom, prenom, formation, promo, groupe_id, en_recherche, profil_visible)
    VALUES (v_utilisateur_id, NEW.nom, NEW.prenom, NEW.formation, NEW.promo, v_groupe_id, false, false)
    RETURNING etudiant_id INTO v_etudiant_id;

    -- 6. Retourner les IDs créés
    NEW.utilisateur_id_created := v_utilisateur_id;
    NEW.etudiant_id_created := v_etudiant_id;

    RETURN NEW;
END;
$$;

alter function fn_creer_etudiant() owner to m1user1_03;

create trigger trg_creer_etudiant
    instead of insert
    on v_action_creer_etudiant
    for each row
execute procedure fn_creer_etudiant();

create function trg_fnc_action_creer_affectation() returns trigger
    language plpgsql
as
$$BEGIN
    -- 1. Mise à jour du statut de la candidature
    -- On passe le statut à 'ACCEPTE' pour confirmer que le processus est terminé
    UPDATE public."Candidature"
    SET statut = 'ACCEPTE'
    WHERE id = NEW.candidature_id;

    -- 2. Création de l'affectation finale (Stage acté)
    INSERT INTO public."Affectation" (candidature_id, date_validation)
    VALUES (NEW.candidature_id, CURRENT_DATE);

    RETURN NEW;
END;$$;

alter function trg_fnc_action_creer_affectation() owner to m1user1_02;

create trigger trg_action_creer_affectation
    instead of insert
    on v_action_creer_affectation
    for each row
execute procedure trg_fnc_action_creer_affectation();

create function fn_creer_groupe() returns trigger
    security definer
    language plpgsql
as
$$
DECLARE
    v_groupe_id INTEGER;
BEGIN
    -- Vérifier que l'enseignant existe et est actif
    IF NOT EXISTS (
        SELECT 1 FROM "Enseignant" e
                          JOIN "Utilisateur" u ON e.utilisateur_id = u.id
        WHERE e.enseignant_id = NEW.enseignant_id AND u.actif = true
    ) THEN
        RAISE EXCEPTION 'Enseignant invalide ou inactif';
    END IF;

    -- Vérifier que la secrétaire existe et est active
    IF NOT EXISTS (
        SELECT 1 FROM "Secretaire" s
                          JOIN "Utilisateur" u ON s.utilisateur_id = u.id
        WHERE s.secretaire_id = NEW.secretaire_id AND u.actif = true
    ) THEN
        RAISE EXCEPTION 'Secrétaire invalide ou inactive';
    END IF;

    -- Créer le groupe
    INSERT INTO "GroupeEtudiant" (nom_groupe, annee_scolaire, enseignant_referent_id, secretaire_gestionnaire_id)
    VALUES (NEW.nom_groupe, NEW.annee_scolaire, NEW.enseignant_id, NEW.secretaire_id)
    RETURNING groupe_id INTO v_groupe_id;

    -- Retourner l'ID créé
    NEW.groupe_id_created := v_groupe_id;

    RETURN NEW;
END;
$$;

alter function fn_creer_groupe() owner to m1user1_03;

create trigger trg_creer_groupe
    instead of insert
    on v_action_creer_groupe
    for each row
execute procedure fn_creer_groupe();

create function fn_modifier_groupe() returns trigger
    security definer
    language plpgsql
as
$$
BEGIN
    -- Vérifier que le groupe existe
    IF NOT EXISTS (SELECT 1 FROM "GroupeEtudiant" WHERE groupe_id = OLD.groupe_id) THEN
        RAISE EXCEPTION 'Groupe non trouvé';
    END IF;

    -- Vérifier que l'enseignant existe et est actif
    IF NOT EXISTS (
        SELECT 1 FROM "Enseignant" e
                          JOIN "Utilisateur" u ON e.utilisateur_id = u.id
        WHERE e.enseignant_id = NEW.enseignant_id AND u.actif = true
    ) THEN
        RAISE EXCEPTION 'Enseignant invalide ou inactif';
    END IF;

    -- Vérifier que la secrétaire existe et est active
    IF NOT EXISTS (
        SELECT 1 FROM "Secretaire" s
                          JOIN "Utilisateur" u ON s.utilisateur_id = u.id
        WHERE s.secretaire_id = NEW.secretaire_id AND u.actif = true
    ) THEN
        RAISE EXCEPTION 'Secrétaire invalide ou inactive';
    END IF;

    -- Mettre à jour le groupe
    UPDATE "GroupeEtudiant"
    SET nom_groupe = NEW.nom_groupe,
        annee_scolaire = NEW.annee_scolaire,
        enseignant_referent_id = NEW.enseignant_id,
        secretaire_gestionnaire_id = NEW.secretaire_id
    WHERE groupe_id = OLD.groupe_id;

    RETURN NEW;
END;
$$;

alter function fn_modifier_groupe() owner to m1user1_03;

create trigger trg_modifier_groupe
    instead of update
    on v_action_modifier_groupe
    for each row
execute procedure fn_modifier_groupe();

create function fn_supprimer_groupe() returns trigger
    security definer
    language plpgsql
as
$$
DECLARE
    v_nb_etudiants INTEGER;
BEGIN
    -- Vérifier que le groupe existe
    IF NOT EXISTS (SELECT 1 FROM "GroupeEtudiant" WHERE groupe_id = OLD.groupe_id) THEN
        RAISE EXCEPTION 'Groupe non trouvé';
    END IF;

    -- Compter les étudiants dans ce groupe
    SELECT COUNT(*) INTO v_nb_etudiants
    FROM "Etudiant"
    WHERE groupe_id = OLD.groupe_id;

    -- Empêcher la suppression si des étudiants sont présents
    IF v_nb_etudiants > 0 THEN
        RAISE EXCEPTION 'Impossible de supprimer un groupe contenant % étudiants', v_nb_etudiants;
    END IF;

    -- Supprimer le groupe
    DELETE FROM "GroupeEtudiant" WHERE groupe_id = OLD.groupe_id;

    RETURN OLD;
END;
$$;

alter function fn_supprimer_groupe() owner to m1user1_03;

create trigger trg_supprimer_groupe
    instead of delete
    on v_action_supprimer_groupe
    for each row
execute procedure fn_supprimer_groupe();

create function fn_creer_enseignant() returns trigger
    security definer
    language plpgsql
as
$$
DECLARE
    v_utilisateur_id INTEGER;
    v_enseignant_id INTEGER;
BEGIN
    -- Vérifier unicité email
    IF EXISTS (SELECT 1 FROM "Utilisateur" WHERE email = NEW.email) THEN
        RAISE EXCEPTION 'Email déjà utilisé : %', NEW.email;
    END IF;

    -- Créer l'utilisateur
    INSERT INTO "Utilisateur" (email, password_hash, role, actif, nom)
    VALUES (NEW.email, NEW.password_hash, 'ENSEIGNANT', true, NEW.nom)
    RETURNING id INTO v_utilisateur_id;

    -- Créer l'enseignant
    INSERT INTO "Enseignant" (utilisateur_id)
    VALUES (v_utilisateur_id)
    RETURNING enseignant_id INTO v_enseignant_id;

    -- Retourner les IDs créés
    NEW.utilisateur_id_created := v_utilisateur_id;
    NEW.enseignant_id_created := v_enseignant_id;

    RETURN NEW;
END;
$$;

alter function fn_creer_enseignant() owner to m1user1_03;

create trigger trg_creer_enseignant
    instead of insert
    on v_action_creer_enseignant
    for each row
execute procedure fn_creer_enseignant();

create function fn_creer_secretaire() returns trigger
    security definer
    language plpgsql
as
$$
DECLARE
    v_utilisateur_id INTEGER;
    v_secretaire_id INTEGER;
BEGIN
    -- Vérifier unicité email
    IF EXISTS (SELECT 1 FROM "Utilisateur" WHERE email = NEW.email) THEN
        RAISE EXCEPTION 'Email déjà utilisé : %', NEW.email;
    END IF;

    -- Créer l'utilisateur
    INSERT INTO "Utilisateur" (email, password_hash, role, actif, nom)
    VALUES (NEW.email, NEW.password_hash, 'SECRETAIRE', true, NEW.nom)
    RETURNING id INTO v_utilisateur_id;

    -- Créer la secrétaire
    INSERT INTO "Secretaire" (utilisateur_id, en_conge)
    VALUES (v_utilisateur_id, false)
    RETURNING secretaire_id INTO v_secretaire_id;

    -- Retourner les IDs créés
    NEW.utilisateur_id_created := v_utilisateur_id;
    NEW.secretaire_id_created := v_secretaire_id;

    RETURN NEW;
END;
$$;

alter function fn_creer_secretaire() owner to m1user1_03;

create trigger trg_creer_secretaire
    instead of insert
    on v_action_creer_secretaire
    for each row
execute procedure fn_creer_secretaire();

create function f_journal_log(p_utilisateur_id integer, p_type journal_type_enum, p_payload text) returns void
    security definer
    SET search_path = public
    language plpgsql
as
$$
BEGIN
    INSERT INTO "JournalEvenement"(utilisateur_id, type, payload)
    VALUES (p_utilisateur_id, p_type, p_payload);
END;
$$;

alter function f_journal_log(integer, journal_type_enum, text) owner to m1user1_04;

grant execute on function f_journal_log(integer, journal_type_enum, text) to role_secretaire;

grant execute on function f_journal_log(integer, journal_type_enum, text) to role_enseignant;

grant execute on function f_journal_log(integer, journal_type_enum, text) to role_etudiant;

grant execute on function f_journal_log(integer, journal_type_enum, text) to role_entreprise;

create function trg_fnc_action_renoncer_candidature() returns trigger
    language plpgsql
as
$$
DECLARE
    v_statut_actuel VARCHAR;
BEGIN
    -- A. Vérifier que la candidature existe
    SELECT statut INTO v_statut_actuel
    FROM public."Candidature"
    WHERE id = NEW.candidature_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Candidature introuvable (ID: %)', NEW.candidature_id;
    END IF;

    -- B. Archivage dans la table Renoncement
    INSERT INTO public."Renoncement" (candidature_id, type_acteur, justification)
    VALUES (NEW.candidature_id, NEW.type_acteur, NEW.justification);

    -- C. Nettoyage de l'Affectation (Si le stage était déjà validé)
    DELETE FROM public."Affectation"
    WHERE candidature_id = NEW.candidature_id;

    -- D. Mise à jour du statut de la Candidature
    -- On utilise 'ANNULE' pour signifier que le processus est stoppé
    UPDATE public."Candidature"
    SET statut = 'ANNULE'
    WHERE id = NEW.candidature_id;

    RETURN NEW;
END;
$$;

alter function trg_fnc_action_renoncer_candidature() owner to m1user1_02;

create trigger trg_action_renoncer_candidature
    instead of insert
    on v_action_renoncer_candidature
    for each row
execute procedure trg_fnc_action_renoncer_candidature();

create function trg_fnc_affectation_cleanup() returns trigger
    language plpgsql
as
$$
DECLARE
    v_offre_id UUID;
    v_etudiant_id UUID;
    v_date_debut_stage DATE;
    v_duree_mois INTEGER;
    v_date_fin_stage DATE;
BEGIN
    -- 1. Récupération des infos contextuelles de l'affectation créée
    -- On remonte vers la candidature et l'offre pour avoir les dates et les IDs
    SELECT
        c.offre_id,
        c.etudiant_id,
        o.date_debut,
        o.duree_mois
    INTO
        v_offre_id,
        v_etudiant_id,
        v_date_debut_stage,
        v_duree_mois
    FROM public."Candidature" c
             JOIN public."Offre" o ON c.offre_id = o.id
    WHERE c.id = NEW.candidature_id;

    -- Calcul de la date de fin pour la comparaison temporelle
    v_date_fin_stage := v_date_debut_stage + (v_duree_mois * INTERVAL '1 month');

    -- =================================================================
    -- RÈGLE 1 : "Offre Pourvue"
    -- On refuse tous les autres candidats sur CETTE offre
    -- =================================================================
    UPDATE public."Candidature"
    SET statut = 'REFUSE'
    WHERE offre_id = v_offre_id
      AND id != NEW.candidature_id -- Sauf celle qu'on vient de valider !
      AND statut NOT IN ('REFUSE', 'ANNULE'); -- Inutile de toucher aux dossiers déjà clos

    -- (Optionnel : Tu pourrais insérer un log ici pour dire "Refus automatique système")


    -- =================================================================
    -- RÈGLE 2 : "Non-Ubiquité" (Chevauchement temporel pour l'étudiant)
    -- On annule les autres candidatures 'RETENU' de cet étudiant qui tombent en même temps
    -- =================================================================

    -- On utilise une sous-requête UPDATE avec jointure pour vérifier les dates
    UPDATE public."Candidature" c
    SET statut = 'REFUSE' -- Ou 'ANNULE' selon ta préférence
    FROM public."Offre" o_other
    WHERE c.offre_id = o_other.id
      AND c.etudiant_id = v_etudiant_id       -- C'est le même étudiant
      AND c.id != NEW.candidature_id          -- Pas l'affectation actuelle
      AND c.statut = 'RETENU'                 -- Seulement celles qui étaient en attente de validation

      -- Logique de chevauchement de dates (OVERLAPS)
      -- Période A (Stage validé) vs Période B (Autre candidature)
      AND (v_date_debut_stage, v_date_fin_stage) OVERLAPS
          (o_other.date_debut, o_other.date_debut + (o_other.duree_mois * INTERVAL '1 month'));

    RETURN NEW;
END;
$$;

alter function trg_fnc_affectation_cleanup() owner to m1user1_02;

create trigger trg_affectation_cleanup
    after insert
    on "Affectation"
    for each row
execute procedure trg_fnc_affectation_cleanup();

create function trg_fnc_action_refuser_candidature() returns trigger
    language plpgsql
as
$$
DECLARE
    v_statut_actuel VARCHAR;
BEGIN
    -- A. Vérification basique
    SELECT statut INTO v_statut_actuel
    FROM public."Candidature"
    WHERE id = NEW.candidature_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Candidature introuvable (ID: %)', NEW.candidature_id;
    END IF;

    -- B. Sécurité : On ne peut pas refuser un dossier déjà acté en stage
    PERFORM 1 FROM public."Affectation" WHERE candidature_id = NEW.candidature_id;
    IF FOUND THEN
        RAISE EXCEPTION 'Action impossible : Une affectation (stage validé) existe déjà.';
    END IF;

    -- C. Action : Changement de statut
    UPDATE public."Candidature"
    SET statut = 'REFUSE'
    WHERE id = NEW.candidature_id;

    RETURN NEW;
END;
$$;

alter function trg_fnc_action_refuser_candidature() owner to m1user1_02;

create trigger trg_action_refuser_candidature
    instead of insert
    on v_action_refuser_candidature
    for each row
execute procedure trg_fnc_action_refuser_candidature();

create function trg_toggle_conge_secretaire() returns trigger
    language plpgsql
as
$$
BEGIN
    UPDATE "Secretaire"
    SET en_conge = NEW.en_conge
    WHERE secretaire_id = NEW.secretaire_id;
    RETURN NEW;
END;
$$;

alter function trg_toggle_conge_secretaire() owner to m1user1_03;

create trigger trg_toggle_conge
    instead of insert
    on v_action_toggle_conge_secretaire
    for each row
execute procedure trg_toggle_conge_secretaire();