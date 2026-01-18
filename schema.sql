create type role_enum as enum ('ETUDIANT', 'ENTREPRISE', 'ENSEIGNANT', 'SECRETAIRE', 'ADMIN');

alter type role_enum owner to m1user1_02;

create type rc_statut_enum as enum ('EN_ATTENTE', 'VALIDE', 'REFUSE');

alter type rc_statut_enum owner to m1user1_02;

create type offre_type_enum as enum ('STAGE', 'ALTERNANCE', 'CDD', '');

alter type offre_type_enum owner to m1user1_02;

create type validation_statut_enum as enum ('BROUILLON', 'EN_ATTENTE', 'VALIDE', 'REFUSE');

alter type validation_statut_enum owner to m1user1_02;

create type cand_statut_enum as enum ('EN_ATTENTE', 'ENTRETIEN', 'RETENU', 'REFUSE', 'ANNULE');

alter type cand_statut_enum owner to m1user1_02;

create type renoncement_type_enum as enum ('etudiant', 'systeme', 'entreprise');

alter type renoncement_type_enum owner to m1user1_02;

create type journal_type_enum as enum ('CONNEXION', 'CREATION', 'MODIFICATION', 'SUPPRESSION', 'ERREUR');

alter type journal_type_enum owner to m1user1_02;

create type notification_type_enum as enum ('OFFRE_SOUMISE', 'OFFRE_VALIDEE', 'OFFRE_REFUSEE', 'CANDIDATURE_RECUE', 'CANDIDATURE_ACCEPTEE', 'CANDIDATURE_REJETEE', 'AFFECTATION_VALIDEE', 'RC_VALIDEE', 'RC_REFUSEE', 'SYSTEME', 'RC_EXPIRATION_PROCHE');

alter type notification_type_enum owner to m1user1_02;

-- Unknown how to generate base type type

alter type gbtreekey4 owner to m1user1_04;

-- Unknown how to generate base type type

alter type gbtreekey8 owner to m1user1_04;

-- Unknown how to generate base type type

alter type gbtreekey16 owner to m1user1_04;

-- Unknown how to generate base type type

alter type gbtreekey32 owner to m1user1_04;

-- Unknown how to generate base type type

alter type gbtreekey_var owner to m1user1_04;

-- Unknown how to generate base type type

alter type gbtreekey2 owner to m1user1_04;

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
    en_conge       boolean,
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

create table "CongeSecretaire"
(
    conge_id                  serial
        primary key,
    secretaire_id             integer                                not null
        references "Secretaire"
            on delete cascade,
    date_debut                date                                   not null,
    date_fin                  date                                   not null,
    remplacant_utilisateur_id integer
                                                                     references "Utilisateur"
                                                                         on delete set null,
    motif                     text,
    annule                    boolean                  default false not null,
    created_at                timestamp with time zone default now() not null,
    constraint conge_no_overlap
        exclude using gist (secretaire_id with =, daterange(date_debut, date_fin, '[]'::text) with &&),
    constraint chk_conge_dates
        check (date_fin >= date_debut)
);

alter table "CongeSecretaire"
    owner to m1user1_04;

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
       a.date_expiration,
       CASE
           WHEN a.date_expiration <= CURRENT_DATE THEN true
           ELSE false
           END AS est_expiree,
       CASE
           WHEN a.date_expiration IS NULL THEN NULL::integer
           ELSE GREATEST(0, a.date_expiration - CURRENT_DATE)
           END AS jours_restants
FROM "Utilisateur" u
         JOIN "Etudiant" e ON e.utilisateur_id = u.id
         LEFT JOIN "AttestationRC" a ON a.etudiant_id = e.etudiant_id;

alter table v_attestation_rc_etudiant
    owner to m1user1_03;

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

create view v_secretaire_autorise_by_user(secretaire_id, utilisateur_id, mode) as
SELECT s.secretaire_id,
       s.utilisateur_id,
       'SECRETAIRE'::text AS mode
FROM "Secretaire" s
UNION ALL
SELECT c.secretaire_id,
       c.remplacant_utilisateur_id AS utilisateur_id,
       'REMPLACANT'::text          AS mode
FROM "CongeSecretaire" c
WHERE c.annule = false
  AND c.remplacant_utilisateur_id IS NOT NULL
  AND CURRENT_DATE >= c.date_debut
  AND CURRENT_DATE <= c.date_fin;

alter table v_secretaire_autorise_by_user
    owner to m1user1_04;

create view v_delegation_secretaire_active_by_user(conge_id, secretaire_id, utilisateur_id, date_debut, date_fin, motif) as
SELECT c.conge_id,
       c.secretaire_id,
       c.remplacant_utilisateur_id AS utilisateur_id,
       c.date_debut,
       c.date_fin,
       c.motif
FROM "CongeSecretaire" c
WHERE c.annule = false
  AND c.remplacant_utilisateur_id IS NOT NULL
  AND CURRENT_DATE >= c.date_debut
  AND CURRENT_DATE <= c.date_fin;

alter table v_delegation_secretaire_active_by_user
    owner to m1user1_04;

create view v_mes_conges_secretaire
            (utilisateur_id, conge_id, secretaire_id, date_debut, date_fin, motif, annule, created_at,
             remplacant_utilisateur_id, remplacant_nom, remplacant_email)
as
SELECT s.utilisateur_id,
       c.conge_id,
       c.secretaire_id,
       c.date_debut,
       c.date_fin,
       c.motif,
       c.annule,
       c.created_at,
       c.remplacant_utilisateur_id,
       ru.nom   AS remplacant_nom,
       ru.email AS remplacant_email
FROM "CongeSecretaire" c
         JOIN "Secretaire" s ON s.secretaire_id = c.secretaire_id
         LEFT JOIN "Utilisateur" ru ON ru.id = c.remplacant_utilisateur_id;

alter table v_mes_conges_secretaire
    owner to m1user1_04;

create view v_action_declarer_conge_secretaire
            (conge_id, secretaire_id, date_debut, date_fin, remplacant_utilisateur_id, motif) as
SELECT c.conge_id,
       c.secretaire_id,
       c.date_debut,
       c.date_fin,
       c.remplacant_utilisateur_id,
       c.motif
FROM "CongeSecretaire" c;

alter table v_action_declarer_conge_secretaire
    owner to m1user1_04;

create view v_profil_secretaire (utilisateur_id, nom, email, role, actif, created_at, secretaire_id, en_conge) as
SELECT u.id                          AS utilisateur_id,
       u.nom,
       u.email,
       u.role,
       u.actif,
       u.created_at,
       s.secretaire_id,
       COALESCE(sec.en_conge, false) AS en_conge
FROM "Secretaire" s
         JOIN "Utilisateur" u ON u.id = s.utilisateur_id
         LEFT JOIN v_secretaire_en_conge sec ON sec.secretaire_id = s.secretaire_id;

alter table v_profil_secretaire
    owner to m1user1_04;

create view v_secretaire_en_conge(secretaire_id, en_conge) as
SELECT v_mes_conges_secretaire.secretaire_id,
       true AS en_conge
FROM v_mes_conges_secretaire
WHERE v_mes_conges_secretaire.annule = false
  AND CURRENT_DATE >= v_mes_conges_secretaire.date_debut
  AND CURRENT_DATE <= v_mes_conges_secretaire.date_fin
GROUP BY v_mes_conges_secretaire.secretaire_id;

alter table v_secretaire_en_conge
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

create function trg_action_postuler_func() returns trigger
    language plpgsql
as
$$
DECLARE
    v_statut_offre validation_statut_enum;
    v_nouvelle_offre_debut DATE;
    v_nouvelle_offre_fin DATE;
    v_conflit_offre_titre TEXT;
BEGIN
    -- 1. Vérification Offre validée
    SELECT statut_validation, date_debut, (date_debut + (duree_mois || ' months')::INTERVAL)::DATE
    INTO v_statut_offre, v_nouvelle_offre_debut, v_nouvelle_offre_fin
    FROM "Offre"
    WHERE id = NEW.offre_id;

    IF v_statut_offre IS DISTINCT FROM 'VALIDE' THEN
        RAISE EXCEPTION 'Impossible de postuler : Cette offre n''est pas disponible.';
    END IF;

    -- 2. Vérification Doublon (candidature existante non annulée)
    IF EXISTS (
        SELECT 1
        FROM "Candidature"
        WHERE offre_id = NEW.offre_id
          AND etudiant_id = NEW.etudiant_id
          AND statut != 'ANNULE'
    ) THEN
        RAISE EXCEPTION 'Vous avez déjà une candidature pour cette offre.';
    END IF;

    -- 3. NOUVEAU : Vérification de chevauchement avec les affectations existantes
    -- On récupère les offres où l'étudiant est affecté (candidature RETENU + affectation)
    -- et on vérifie si les dates chevauchent
    SELECT o.titre INTO v_conflit_offre_titre
    FROM "Affectation" a
             JOIN "Candidature" c ON a.candidature_id = c.id
             JOIN "Offre" o ON c.offre_id = o.id
    WHERE c.etudiant_id = NEW.etudiant_id
      AND c.statut = 'RETENU'
      -- Vérification du chevauchement de dates
      -- Période existante : [o.date_debut, o.date_debut + duree_mois]
      -- Période nouvelle : [v_nouvelle_offre_debut, v_nouvelle_offre_fin]
      -- Chevauchement si : debut1 < fin2 AND debut2 < fin1
      AND o.date_debut < v_nouvelle_offre_fin
      AND v_nouvelle_offre_debut < (o.date_debut + (o.duree_mois || ' months')::INTERVAL)::DATE
    LIMIT 1;

    IF v_conflit_offre_titre IS NOT NULL THEN
        RAISE EXCEPTION 'Impossible de postuler : Vous êtes déjà affecté(e) à une offre dont les dates chevauchent cette période (%).',
            v_conflit_offre_titre;
    END IF;

    -- 4. Insertion de la candidature
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

create function trg_action_deposer_attestation_rc_func() returns trigger
    language plpgsql
as
$$
DECLARE
    v_statut_existant rc_statut_enum;
    v_date_expiration_existante date;
    v_nouvelle_date_expiration date;
BEGIN
    v_nouvelle_date_expiration := make_date(EXTRACT(YEAR FROM CURRENT_DATE)::int + 1, 1, 1);

    SELECT statut, date_expiration
    INTO v_statut_existant, v_date_expiration_existante
    FROM "AttestationRC"
    WHERE etudiant_id = NEW.etudiant_id;

    -- Cas A : aucune attestation -> insertion
    IF NOT FOUND THEN
        INSERT INTO "AttestationRC" (etudiant_id, statut, fichier_url, date_depot, date_validation, date_expiration)
        VALUES (NEW.etudiant_id, 'EN_ATTENTE', NEW.fichier_url, CURRENT_DATE, NULL, v_nouvelle_date_expiration);
        RETURN NEW;
    END IF;

    -- Cas B : REFUSE -> redépôt
    IF v_statut_existant = 'REFUSE' THEN
        UPDATE "AttestationRC"
        SET fichier_url = NEW.fichier_url, statut = 'EN_ATTENTE', date_depot = CURRENT_DATE,
            date_validation = NULL, date_expiration = v_nouvelle_date_expiration
        WHERE etudiant_id = NEW.etudiant_id;
        RETURN NEW;
    END IF;

    -- Cas C : VALIDE mais expirée -> redépôt
    IF v_statut_existant = 'VALIDE' AND v_date_expiration_existante <= CURRENT_DATE THEN
        UPDATE "AttestationRC"
        SET fichier_url = NEW.fichier_url, statut = 'EN_ATTENTE', date_depot = CURRENT_DATE,
            date_validation = NULL, date_expiration = v_nouvelle_date_expiration
        WHERE etudiant_id = NEW.etudiant_id;
        RETURN NEW;
    END IF;

    -- Cas D : VALIDE non expirée -> interdit
    IF v_statut_existant = 'VALIDE' THEN
        RAISE EXCEPTION 'Dépôt impossible : attestation valide jusqu''au %.', to_char(v_date_expiration_existante, 'DD/MM/YYYY');
    END IF;

    -- Cas E : EN_ATTENTE -> interdit
    RAISE EXCEPTION 'Dépôt impossible : attestation déjà en attente de validation.';
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

create function gbtreekey4_in(cstring) returns gbtreekey4
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbtreekey4_in(cstring) owner to m1user1_04;

create function gbtreekey4_out(gbtreekey4) returns cstring
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbtreekey4_out(gbtreekey4) owner to m1user1_04;

create function gbtreekey8_in(cstring) returns gbtreekey8
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbtreekey8_in(cstring) owner to m1user1_04;

create function gbtreekey8_out(gbtreekey8) returns cstring
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbtreekey8_out(gbtreekey8) owner to m1user1_04;

create function gbtreekey16_in(cstring) returns gbtreekey16
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbtreekey16_in(cstring) owner to m1user1_04;

create function gbtreekey16_out(gbtreekey16) returns cstring
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbtreekey16_out(gbtreekey16) owner to m1user1_04;

create function gbtreekey32_in(cstring) returns gbtreekey32
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbtreekey32_in(cstring) owner to m1user1_04;

create function gbtreekey32_out(gbtreekey32) returns cstring
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbtreekey32_out(gbtreekey32) owner to m1user1_04;

create function gbtreekey_var_in(cstring) returns gbtreekey_var
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbtreekey_var_in(cstring) owner to m1user1_04;

create function gbtreekey_var_out(gbtreekey_var) returns cstring
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbtreekey_var_out(gbtreekey_var) owner to m1user1_04;

create function cash_dist(money, money) returns money
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function cash_dist(money, money) owner to m1user1_04;

create function date_dist(date, date) returns integer
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function date_dist(date, date) owner to m1user1_04;

create function float4_dist(real, real) returns real
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function float4_dist(real, real) owner to m1user1_04;

create function float8_dist(double precision, double precision) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function float8_dist(double precision, double precision) owner to m1user1_04;

create function int2_dist(smallint, smallint) returns smallint
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function int2_dist(smallint, smallint) owner to m1user1_04;

create function int4_dist(integer, integer) returns integer
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function int4_dist(integer, integer) owner to m1user1_04;

create function int8_dist(bigint, bigint) returns bigint
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function int8_dist(bigint, bigint) owner to m1user1_04;

create function interval_dist(interval, interval) returns interval
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function interval_dist(interval, interval) owner to m1user1_04;

create function oid_dist(oid, oid) returns oid
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function oid_dist(oid, oid) owner to m1user1_04;

create function time_dist(time, time) returns interval
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function time_dist(time, time) owner to m1user1_04;

create function ts_dist(timestamp, timestamp) returns interval
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function ts_dist(timestamp, timestamp) owner to m1user1_04;

create function tstz_dist(timestamp with time zone, timestamp with time zone) returns interval
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function tstz_dist(timestamp with time zone, timestamp with time zone) owner to m1user1_04;

create function gbt_oid_consistent(internal, oid, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_oid_consistent(internal, oid, smallint, oid, internal) owner to m1user1_04;

create function gbt_oid_distance(internal, oid, smallint, oid, internal) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_oid_distance(internal, oid, smallint, oid, internal) owner to m1user1_04;

create function gbt_oid_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_oid_fetch(internal) owner to m1user1_04;

create function gbt_oid_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_oid_compress(internal) owner to m1user1_04;

create function gbt_decompress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_decompress(internal) owner to m1user1_04;

create function gbt_var_decompress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_var_decompress(internal) owner to m1user1_04;

create function gbt_var_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_var_fetch(internal) owner to m1user1_04;

create function gbt_oid_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_oid_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_oid_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_oid_picksplit(internal, internal) owner to m1user1_04;

create function gbt_oid_union(internal, internal) returns gbtreekey8
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_oid_union(internal, internal) owner to m1user1_04;

create function gbt_oid_same(gbtreekey8, gbtreekey8, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_oid_same(gbtreekey8, gbtreekey8, internal) owner to m1user1_04;

create function gbt_int2_consistent(internal, smallint, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int2_consistent(internal, smallint, smallint, oid, internal) owner to m1user1_04;

create function gbt_int2_distance(internal, smallint, smallint, oid, internal) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int2_distance(internal, smallint, smallint, oid, internal) owner to m1user1_04;

create function gbt_int2_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int2_compress(internal) owner to m1user1_04;

create function gbt_int2_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int2_fetch(internal) owner to m1user1_04;

create function gbt_int2_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int2_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_int2_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int2_picksplit(internal, internal) owner to m1user1_04;

create function gbt_int2_union(internal, internal) returns gbtreekey4
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int2_union(internal, internal) owner to m1user1_04;

create function gbt_int2_same(gbtreekey4, gbtreekey4, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int2_same(gbtreekey4, gbtreekey4, internal) owner to m1user1_04;

create function gbt_int4_consistent(internal, integer, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int4_consistent(internal, integer, smallint, oid, internal) owner to m1user1_04;

create function gbt_int4_distance(internal, integer, smallint, oid, internal) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int4_distance(internal, integer, smallint, oid, internal) owner to m1user1_04;

create function gbt_int4_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int4_compress(internal) owner to m1user1_04;

create function gbt_int4_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int4_fetch(internal) owner to m1user1_04;

create function gbt_int4_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int4_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_int4_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int4_picksplit(internal, internal) owner to m1user1_04;

create function gbt_int4_union(internal, internal) returns gbtreekey8
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int4_union(internal, internal) owner to m1user1_04;

create function gbt_int4_same(gbtreekey8, gbtreekey8, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int4_same(gbtreekey8, gbtreekey8, internal) owner to m1user1_04;

create function gbt_int8_consistent(internal, bigint, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int8_consistent(internal, bigint, smallint, oid, internal) owner to m1user1_04;

create function gbt_int8_distance(internal, bigint, smallint, oid, internal) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int8_distance(internal, bigint, smallint, oid, internal) owner to m1user1_04;

create function gbt_int8_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int8_compress(internal) owner to m1user1_04;

create function gbt_int8_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int8_fetch(internal) owner to m1user1_04;

create function gbt_int8_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int8_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_int8_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int8_picksplit(internal, internal) owner to m1user1_04;

create function gbt_int8_union(internal, internal) returns gbtreekey16
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int8_union(internal, internal) owner to m1user1_04;

create function gbt_int8_same(gbtreekey16, gbtreekey16, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_int8_same(gbtreekey16, gbtreekey16, internal) owner to m1user1_04;

create function gbt_float4_consistent(internal, real, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float4_consistent(internal, real, smallint, oid, internal) owner to m1user1_04;

create function gbt_float4_distance(internal, real, smallint, oid, internal) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float4_distance(internal, real, smallint, oid, internal) owner to m1user1_04;

create function gbt_float4_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float4_compress(internal) owner to m1user1_04;

create function gbt_float4_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float4_fetch(internal) owner to m1user1_04;

create function gbt_float4_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float4_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_float4_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float4_picksplit(internal, internal) owner to m1user1_04;

create function gbt_float4_union(internal, internal) returns gbtreekey8
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float4_union(internal, internal) owner to m1user1_04;

create function gbt_float4_same(gbtreekey8, gbtreekey8, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float4_same(gbtreekey8, gbtreekey8, internal) owner to m1user1_04;

create function gbt_float8_consistent(internal, double precision, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float8_consistent(internal, double precision, smallint, oid, internal) owner to m1user1_04;

create function gbt_float8_distance(internal, double precision, smallint, oid, internal) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float8_distance(internal, double precision, smallint, oid, internal) owner to m1user1_04;

create function gbt_float8_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float8_compress(internal) owner to m1user1_04;

create function gbt_float8_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float8_fetch(internal) owner to m1user1_04;

create function gbt_float8_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float8_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_float8_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float8_picksplit(internal, internal) owner to m1user1_04;

create function gbt_float8_union(internal, internal) returns gbtreekey16
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float8_union(internal, internal) owner to m1user1_04;

create function gbt_float8_same(gbtreekey16, gbtreekey16, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_float8_same(gbtreekey16, gbtreekey16, internal) owner to m1user1_04;

create function gbt_ts_consistent(internal, timestamp, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_ts_consistent(internal, timestamp, smallint, oid, internal) owner to m1user1_04;

create function gbt_ts_distance(internal, timestamp, smallint, oid, internal) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_ts_distance(internal, timestamp, smallint, oid, internal) owner to m1user1_04;

create function gbt_tstz_consistent(internal, timestamp with time zone, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_tstz_consistent(internal, timestamp with time zone, smallint, oid, internal) owner to m1user1_04;

create function gbt_tstz_distance(internal, timestamp with time zone, smallint, oid, internal) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_tstz_distance(internal, timestamp with time zone, smallint, oid, internal) owner to m1user1_04;

create function gbt_ts_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_ts_compress(internal) owner to m1user1_04;

create function gbt_tstz_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_tstz_compress(internal) owner to m1user1_04;

create function gbt_ts_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_ts_fetch(internal) owner to m1user1_04;

create function gbt_ts_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_ts_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_ts_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_ts_picksplit(internal, internal) owner to m1user1_04;

create function gbt_ts_union(internal, internal) returns gbtreekey16
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_ts_union(internal, internal) owner to m1user1_04;

create function gbt_ts_same(gbtreekey16, gbtreekey16, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_ts_same(gbtreekey16, gbtreekey16, internal) owner to m1user1_04;

create function gbt_time_consistent(internal, time, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_time_consistent(internal, time, smallint, oid, internal) owner to m1user1_04;

create function gbt_time_distance(internal, time, smallint, oid, internal) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_time_distance(internal, time, smallint, oid, internal) owner to m1user1_04;

create function gbt_timetz_consistent(internal, time with time zone, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_timetz_consistent(internal, time with time zone, smallint, oid, internal) owner to m1user1_04;

create function gbt_time_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_time_compress(internal) owner to m1user1_04;

create function gbt_timetz_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_timetz_compress(internal) owner to m1user1_04;

create function gbt_time_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_time_fetch(internal) owner to m1user1_04;

create function gbt_time_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_time_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_time_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_time_picksplit(internal, internal) owner to m1user1_04;

create function gbt_time_union(internal, internal) returns gbtreekey16
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_time_union(internal, internal) owner to m1user1_04;

create function gbt_time_same(gbtreekey16, gbtreekey16, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_time_same(gbtreekey16, gbtreekey16, internal) owner to m1user1_04;

create function gbt_date_consistent(internal, date, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_date_consistent(internal, date, smallint, oid, internal) owner to m1user1_04;

create function gbt_date_distance(internal, date, smallint, oid, internal) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_date_distance(internal, date, smallint, oid, internal) owner to m1user1_04;

create function gbt_date_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_date_compress(internal) owner to m1user1_04;

create function gbt_date_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_date_fetch(internal) owner to m1user1_04;

create function gbt_date_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_date_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_date_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_date_picksplit(internal, internal) owner to m1user1_04;

create function gbt_date_union(internal, internal) returns gbtreekey8
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_date_union(internal, internal) owner to m1user1_04;

create function gbt_date_same(gbtreekey8, gbtreekey8, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_date_same(gbtreekey8, gbtreekey8, internal) owner to m1user1_04;

create function gbt_intv_consistent(internal, interval, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_intv_consistent(internal, interval, smallint, oid, internal) owner to m1user1_04;

create function gbt_intv_distance(internal, interval, smallint, oid, internal) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_intv_distance(internal, interval, smallint, oid, internal) owner to m1user1_04;

create function gbt_intv_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_intv_compress(internal) owner to m1user1_04;

create function gbt_intv_decompress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_intv_decompress(internal) owner to m1user1_04;

create function gbt_intv_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_intv_fetch(internal) owner to m1user1_04;

create function gbt_intv_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_intv_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_intv_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_intv_picksplit(internal, internal) owner to m1user1_04;

create function gbt_intv_union(internal, internal) returns gbtreekey32
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_intv_union(internal, internal) owner to m1user1_04;

create function gbt_intv_same(gbtreekey32, gbtreekey32, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_intv_same(gbtreekey32, gbtreekey32, internal) owner to m1user1_04;

create function gbt_cash_consistent(internal, money, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_cash_consistent(internal, money, smallint, oid, internal) owner to m1user1_04;

create function gbt_cash_distance(internal, money, smallint, oid, internal) returns double precision
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_cash_distance(internal, money, smallint, oid, internal) owner to m1user1_04;

create function gbt_cash_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_cash_compress(internal) owner to m1user1_04;

create function gbt_cash_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_cash_fetch(internal) owner to m1user1_04;

create function gbt_cash_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_cash_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_cash_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_cash_picksplit(internal, internal) owner to m1user1_04;

create function gbt_cash_union(internal, internal) returns gbtreekey16
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_cash_union(internal, internal) owner to m1user1_04;

create function gbt_cash_same(gbtreekey16, gbtreekey16, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_cash_same(gbtreekey16, gbtreekey16, internal) owner to m1user1_04;

create function gbt_macad_consistent(internal, macaddr, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad_consistent(internal, macaddr, smallint, oid, internal) owner to m1user1_04;

create function gbt_macad_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad_compress(internal) owner to m1user1_04;

create function gbt_macad_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad_fetch(internal) owner to m1user1_04;

create function gbt_macad_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_macad_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad_picksplit(internal, internal) owner to m1user1_04;

create function gbt_macad_union(internal, internal) returns gbtreekey16
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad_union(internal, internal) owner to m1user1_04;

create function gbt_macad_same(gbtreekey16, gbtreekey16, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad_same(gbtreekey16, gbtreekey16, internal) owner to m1user1_04;

create function gbt_text_consistent(internal, text, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_text_consistent(internal, text, smallint, oid, internal) owner to m1user1_04;

create function gbt_bpchar_consistent(internal, char, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bpchar_consistent(internal, char, smallint, oid, internal) owner to m1user1_04;

create function gbt_text_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_text_compress(internal) owner to m1user1_04;

create function gbt_bpchar_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bpchar_compress(internal) owner to m1user1_04;

create function gbt_text_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_text_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_text_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_text_picksplit(internal, internal) owner to m1user1_04;

create function gbt_text_union(internal, internal) returns gbtreekey_var
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_text_union(internal, internal) owner to m1user1_04;

create function gbt_text_same(gbtreekey_var, gbtreekey_var, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_text_same(gbtreekey_var, gbtreekey_var, internal) owner to m1user1_04;

create function gbt_bytea_consistent(internal, bytea, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bytea_consistent(internal, bytea, smallint, oid, internal) owner to m1user1_04;

create function gbt_bytea_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bytea_compress(internal) owner to m1user1_04;

create function gbt_bytea_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bytea_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_bytea_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bytea_picksplit(internal, internal) owner to m1user1_04;

create function gbt_bytea_union(internal, internal) returns gbtreekey_var
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bytea_union(internal, internal) owner to m1user1_04;

create function gbt_bytea_same(gbtreekey_var, gbtreekey_var, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bytea_same(gbtreekey_var, gbtreekey_var, internal) owner to m1user1_04;

create function gbt_numeric_consistent(internal, numeric, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_numeric_consistent(internal, numeric, smallint, oid, internal) owner to m1user1_04;

create function gbt_numeric_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_numeric_compress(internal) owner to m1user1_04;

create function gbt_numeric_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_numeric_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_numeric_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_numeric_picksplit(internal, internal) owner to m1user1_04;

create function gbt_numeric_union(internal, internal) returns gbtreekey_var
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_numeric_union(internal, internal) owner to m1user1_04;

create function gbt_numeric_same(gbtreekey_var, gbtreekey_var, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_numeric_same(gbtreekey_var, gbtreekey_var, internal) owner to m1user1_04;

create function gbt_bit_consistent(internal, bit, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bit_consistent(internal, bit, smallint, oid, internal) owner to m1user1_04;

create function gbt_bit_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bit_compress(internal) owner to m1user1_04;

create function gbt_bit_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bit_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_bit_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bit_picksplit(internal, internal) owner to m1user1_04;

create function gbt_bit_union(internal, internal) returns gbtreekey_var
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bit_union(internal, internal) owner to m1user1_04;

create function gbt_bit_same(gbtreekey_var, gbtreekey_var, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bit_same(gbtreekey_var, gbtreekey_var, internal) owner to m1user1_04;

create function gbt_inet_consistent(internal, inet, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_inet_consistent(internal, inet, smallint, oid, internal) owner to m1user1_04;

create function gbt_inet_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_inet_compress(internal) owner to m1user1_04;

create function gbt_inet_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_inet_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_inet_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_inet_picksplit(internal, internal) owner to m1user1_04;

create function gbt_inet_union(internal, internal) returns gbtreekey16
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_inet_union(internal, internal) owner to m1user1_04;

create function gbt_inet_same(gbtreekey16, gbtreekey16, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_inet_same(gbtreekey16, gbtreekey16, internal) owner to m1user1_04;

create function gbt_uuid_consistent(internal, uuid, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_uuid_consistent(internal, uuid, smallint, oid, internal) owner to m1user1_04;

create function gbt_uuid_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_uuid_fetch(internal) owner to m1user1_04;

create function gbt_uuid_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_uuid_compress(internal) owner to m1user1_04;

create function gbt_uuid_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_uuid_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_uuid_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_uuid_picksplit(internal, internal) owner to m1user1_04;

create function gbt_uuid_union(internal, internal) returns gbtreekey32
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_uuid_union(internal, internal) owner to m1user1_04;

create function gbt_uuid_same(gbtreekey32, gbtreekey32, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_uuid_same(gbtreekey32, gbtreekey32, internal) owner to m1user1_04;

create function gbt_macad8_consistent(internal, macaddr8, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad8_consistent(internal, macaddr8, smallint, oid, internal) owner to m1user1_04;

create function gbt_macad8_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad8_compress(internal) owner to m1user1_04;

create function gbt_macad8_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad8_fetch(internal) owner to m1user1_04;

create function gbt_macad8_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad8_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_macad8_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad8_picksplit(internal, internal) owner to m1user1_04;

create function gbt_macad8_union(internal, internal) returns gbtreekey16
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad8_union(internal, internal) owner to m1user1_04;

create function gbt_macad8_same(gbtreekey16, gbtreekey16, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_macad8_same(gbtreekey16, gbtreekey16, internal) owner to m1user1_04;

create function gbt_enum_consistent(internal, anyenum, smallint, oid, internal) returns boolean
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_enum_consistent(internal, anyenum, smallint, oid, internal) owner to m1user1_04;

create function gbt_enum_compress(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_enum_compress(internal) owner to m1user1_04;

create function gbt_enum_fetch(internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_enum_fetch(internal) owner to m1user1_04;

create function gbt_enum_penalty(internal, internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_enum_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_enum_picksplit(internal, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_enum_picksplit(internal, internal) owner to m1user1_04;

create function gbt_enum_union(internal, internal) returns gbtreekey8
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_enum_union(internal, internal) owner to m1user1_04;

create function gbt_enum_same(gbtreekey8, gbtreekey8, internal) returns internal
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_enum_same(gbtreekey8, gbtreekey8, internal) owner to m1user1_04;

create function gbtreekey2_in(cstring) returns gbtreekey2
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbtreekey2_in(cstring) owner to m1user1_04;

create function gbtreekey2_out(gbtreekey2) returns cstring
    immutable
    strict
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbtreekey2_out(gbtreekey2) owner to m1user1_04;

create function gbt_bool_consistent(internal, boolean, smallint, oid, internal) returns boolean
    immutable
    strict
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bool_consistent(internal, boolean, smallint, oid, internal) owner to m1user1_04;

create function gbt_bool_compress(internal) returns internal
    immutable
    strict
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bool_compress(internal) owner to m1user1_04;

create function gbt_bool_fetch(internal) returns internal
    immutable
    strict
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bool_fetch(internal) owner to m1user1_04;

create function gbt_bool_penalty(internal, internal, internal) returns internal
    immutable
    strict
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bool_penalty(internal, internal, internal) owner to m1user1_04;

create function gbt_bool_picksplit(internal, internal) returns internal
    immutable
    strict
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bool_picksplit(internal, internal) owner to m1user1_04;

create function gbt_bool_union(internal, internal) returns gbtreekey2
    immutable
    strict
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bool_union(internal, internal) owner to m1user1_04;

create function gbt_bool_same(gbtreekey2, gbtreekey2, internal) returns internal
    immutable
    strict
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function gbt_bool_same(gbtreekey2, gbtreekey2, internal) owner to m1user1_04;

create function trg_action_declarer_conge_secretaire_ins() returns trigger
    language plpgsql
as
$$
DECLARE
    v_role role_enum;
BEGIN
    IF NEW.date_fin < NEW.date_debut THEN
        RAISE EXCEPTION 'date_fin doit être >= date_debut';
    END IF;

    -- si remplaçant fourni, doit être ENSEIGNANT (ou ADMIN si vous voulez)
    IF NEW.remplacant_utilisateur_id IS NOT NULL THEN
        SELECT u.role INTO v_role
        FROM "Utilisateur" u
        WHERE u.id = NEW.remplacant_utilisateur_id;

        IF v_role IS NULL THEN
            RAISE EXCEPTION 'Remplaçant introuvable';
        END IF;

        IF v_role <> 'ENSEIGNANT' AND v_role <> 'ADMIN' THEN
            RAISE EXCEPTION 'Le remplaçant doit être ENSEIGNANT (ou ADMIN)';
        END IF;
    END IF;

    INSERT INTO "CongeSecretaire"(secretaire_id, date_debut, date_fin, remplacant_utilisateur_id, motif)
    VALUES (NEW.secretaire_id, NEW.date_debut, NEW.date_fin, NEW.remplacant_utilisateur_id, NEW.motif)
    RETURNING conge_id INTO NEW.conge_id;

    RETURN NEW;
END;
$$;

alter function trg_action_declarer_conge_secretaire_ins() owner to m1user1_04;

create trigger trg_action_declarer_conge_secretaire_ins
    instead of insert
    on v_action_declarer_conge_secretaire
    for each row
execute procedure trg_action_declarer_conge_secretaire_ins();

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
$$
DECLARE
    v_etudiant_user_id INTEGER;
    v_offre_titre VARCHAR(255);
    v_entreprise_nom VARCHAR(255);
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

    SELECT o.titre, ent.raison_sociale
    INTO v_offre_titre, v_entreprise_nom
    FROM "Offre" o
             JOIN "Entreprise" ent ON ent.entreprise_id = o.entreprise_id
    WHERE o.id = NEW.offre_id;

    IF v_etudiant_user_id IS NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.statut = 'RETENU' THEN
        v_type := 'CANDIDATURE_ACCEPTEE';
        v_titre := 'Candidature retenue';
        v_message := format('%s a retenu votre candidature pour le poste "%s" !',
                            COALESCE(v_entreprise_nom, 'Une entreprise'),
                            COALESCE(v_offre_titre, 'l''offre'));
    ELSIF NEW.statut = 'ENTRETIEN' THEN
        v_type := 'CANDIDATURE_ACCEPTEE';
        v_titre := 'Entretien programme';
        v_message := format('%s souhaite vous rencontrer pour le poste "%s".',
                            COALESCE(v_entreprise_nom, 'Une entreprise'),
                            COALESCE(v_offre_titre, 'l''offre'));
    ELSIF NEW.statut = 'REFUSE' THEN
        v_type := 'CANDIDATURE_REJETEE';
        v_titre := 'Candidature non retenue';
        v_message := format('Votre candidature pour "%s" chez %s n''a pas été retenue.',
                            COALESCE(v_offre_titre, 'l''offre'),
                            COALESCE(v_entreprise_nom, 'l''entreprise'));
    ELSE
        RETURN NEW;
    END IF;

    PERFORM fn_creer_notification(
            v_etudiant_user_id,
            v_type,
            v_titre,
            v_message,
            '/candidatures',
            'candidature',
            NEW.id
            );
    RETURN NEW;
END;
$$;

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
$$
DECLARE
    v_etudiant_id UUID;
    v_offre_id UUID;
    v_statut_candidature VARCHAR;
    v_enseignant_ref_id INTEGER;
    v_date_debut DATE;
    v_duree_semaines INTEGER;
    v_date_fin_estimee DATE;
BEGIN
    -- A. Récupération des infos contextuelles (Etudiant, Offre, Statut)
    SELECT
        c.etudiant_id,
        c.offre_id,
        c.statut,
        o.date_debut,
        o.duree_semaines -- Supposons que tu as ce champ dans Offre
    INTO
        v_etudiant_id,
        v_offre_id,
        v_statut_candidature,
        v_date_debut,
        v_duree_semaines
    FROM public."Candidature" c
             JOIN public."Offre" o ON c.offre_id = o.id
    WHERE c.id = NEW.candidature_id;

    -- B. Vérification 1 : Existence
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Candidature introuvable (ID: %)', NEW.candidature_id;
    END IF;

    -- C. Vérification 2 : Règle Critique (Statut)
    IF v_statut_candidature != 'RETENU' THEN
        RAISE EXCEPTION 'Blocage Sécurité : Impossible de créer une affectation. La candidature doit être au statut RETENU (Statut actuel : %)', v_statut_candidature;
    END IF;

    -- D. Vérification 3 : Doublons
    PERFORM 1 FROM public."Affectation"
    WHERE etudiant_id = v_etudiant_id AND offre_id = v_offre_id;

    IF FOUND THEN
        RAISE EXCEPTION 'Une affectation existe déjà pour cet étudiant sur cette offre.';
    END IF;

    -- E. "Auto-Wiring" : Récupération automatique du Professeur Référent via le Groupe
    -- C'est ici qu'on utilise ta nouvelle table GroupeEtudiant !
    SELECT g.enseignant_referent_id
    INTO v_enseignant_ref_id
    FROM public."Etudiant" e
             JOIN public."GroupeEtudiant" g ON e.groupe_id = g.groupe_id
    WHERE e.etudiant_id = v_etudiant_id;

    -- Calcul de la date de fin (si dispo, sinon NULL)
    IF v_date_debut IS NOT NULL AND v_duree_semaines IS NOT NULL THEN
        v_date_fin_estimee := v_date_debut + (v_duree_semaines * 7);
    ELSE
        v_date_fin_estimee := NULL; -- Sera rempli plus tard manuellement si besoin
    END IF;

    -- F. Action Finale : Insertion propre dans la table Affectation
    INSERT INTO public."Affectation" (
        etudiant_id,
        offre_id,
        enseignant_id, -- On assigne automatiquement le prof du groupe !
        date_debut,
        date_fin,
        date_creation -- Supposant que tu as ce champ
    ) VALUES (
                 v_etudiant_id,
                 v_offre_id,
                 v_enseignant_ref_id, -- Peut être NULL si l'étudiant n'a pas de groupe, PostgreSQL gèrera
                 v_date_debut,
                 v_date_fin_estimee,
                 NOW()
             );

    RETURN NEW;
END;
$$;

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

create operator <-> (procedure = cash_dist, leftarg = money, rightarg = money, commutator = <->);

alter operator <->(money, money) owner to m1user1_04;

create operator <-> (procedure = date_dist, leftarg = date, rightarg = date, commutator = <->);

alter operator <->(date, date) owner to m1user1_04;

create operator <-> (procedure = float4_dist, leftarg = real, rightarg = real, commutator = <->);

alter operator <->(real, real) owner to m1user1_04;

create operator <-> (procedure = float8_dist, leftarg = double precision, rightarg = double precision, commutator = <->);

alter operator <->(double precision, double precision) owner to m1user1_04;

create operator <-> (procedure = int2_dist, leftarg = smallint, rightarg = smallint, commutator = <->);

alter operator <->(smallint, smallint) owner to m1user1_04;

create operator <-> (procedure = int4_dist, leftarg = integer, rightarg = integer, commutator = <->);

alter operator <->(integer, integer) owner to m1user1_04;

create operator <-> (procedure = int8_dist, leftarg = bigint, rightarg = bigint, commutator = <->);

alter operator <->(bigint, bigint) owner to m1user1_04;

create operator <-> (procedure = interval_dist, leftarg = interval, rightarg = interval, commutator = <->);

alter operator <->(interval, interval) owner to m1user1_04;

create operator <-> (procedure = oid_dist, leftarg = oid, rightarg = oid, commutator = <->);

alter operator <->(oid, oid) owner to m1user1_04;

create operator <-> (procedure = time_dist, leftarg = time, rightarg = time, commutator = <->);

alter operator <->(time, time) owner to m1user1_04;

create operator <-> (procedure = ts_dist, leftarg = timestamp, rightarg = timestamp, commutator = <->);

alter operator <->(timestamp, timestamp) owner to m1user1_04;

create operator <-> (procedure = tstz_dist, leftarg = timestamp with time zone, rightarg = timestamp with time zone, commutator = <->);

alter operator <->(timestamp with time zone, timestamp with time zone) owner to m1user1_04;

create operator family gist_oid_ops using gist;

alter operator family gist_oid_ops using gist add
    operator 1 <(oid,oid),
    operator 2 <=(oid,oid),
    operator 3 =(oid,oid),
    operator 4 >=(oid,oid),
    operator 5 >(oid,oid),
    operator 6 <>(oid,oid),
    operator 15 <->(oid, oid) for order by oid_ops,
    function 4(oid, oid) gbt_decompress(internal),
    function 5(oid, oid) gbt_oid_penalty(internal, internal, internal),
    function 1(oid, oid) gbt_oid_consistent(internal, oid, smallint, oid, internal),
    function 6(oid, oid) gbt_oid_picksplit(internal, internal),
    function 7(oid, oid) gbt_oid_same(gbtreekey8, gbtreekey8, internal),
    function 9(oid, oid) gbt_oid_fetch(internal),
    function 8(oid, oid) gbt_oid_distance(internal, oid, smallint, oid, internal),
    function 3(oid, oid) gbt_oid_compress(internal),
    function 2(oid, oid) gbt_oid_union(internal, internal);

alter operator family gist_oid_ops using gist owner to m1user1_04;

create operator class gist_oid_ops default for type oid using gist as storage gbtreekey8 function 7(oid, oid) gbt_oid_same(gbtreekey8, gbtreekey8, internal),
	function 1(oid, oid) gbt_oid_consistent(internal, oid, smallint, oid, internal),
	function 5(oid, oid) gbt_oid_penalty(internal, internal, internal),
	function 6(oid, oid) gbt_oid_picksplit(internal, internal),
	function 2(oid, oid) gbt_oid_union(internal, internal);

alter operator class gist_oid_ops using gist owner to m1user1_04;

create operator family gist_int2_ops using gist;

alter operator family gist_int2_ops using gist add
    operator 1 <(smallint,smallint),
    operator 2 <=(smallint,smallint),
    operator 3 =(smallint,smallint),
    operator 4 >=(smallint,smallint),
    operator 5 >(smallint,smallint),
    operator 6 <>(smallint,smallint),
    operator 15 <->(smallint, smallint) for order by integer_ops,
    function 9(smallint, smallint) gbt_int2_fetch(internal),
    function 3(smallint, smallint) gbt_int2_compress(internal),
    function 2(smallint, smallint) gbt_int2_union(internal, internal),
    function 1(smallint, smallint) gbt_int2_consistent(internal, smallint, smallint, oid, internal),
    function 5(smallint, smallint) gbt_int2_penalty(internal, internal, internal),
    function 6(smallint, smallint) gbt_int2_picksplit(internal, internal),
    function 4(smallint, smallint) gbt_decompress(internal),
    function 7(smallint, smallint) gbt_int2_same(gbtreekey4, gbtreekey4, internal),
    function 8(smallint, smallint) gbt_int2_distance(internal, smallint, smallint, oid, internal);

alter operator family gist_int2_ops using gist owner to m1user1_04;

create operator class gist_int2_ops default for type smallint using gist as storage gbtreekey4 function 2(smallint, smallint) gbt_int2_union(internal, internal),
	function 1(smallint, smallint) gbt_int2_consistent(internal, smallint, smallint, oid, internal),
	function 6(smallint, smallint) gbt_int2_picksplit(internal, internal),
	function 7(smallint, smallint) gbt_int2_same(gbtreekey4, gbtreekey4, internal),
	function 5(smallint, smallint) gbt_int2_penalty(internal, internal, internal);

alter operator class gist_int2_ops using gist owner to m1user1_04;

create operator family gist_int4_ops using gist;

alter operator family gist_int4_ops using gist add
    operator 1 <(integer,integer),
    operator 2 <=(integer,integer),
    operator 3 =(integer,integer),
    operator 4 >=(integer,integer),
    operator 5 >(integer,integer),
    operator 6 <>(integer,integer),
    operator 15 <->(integer, integer) for order by integer_ops,
    function 7(integer, integer) gbt_int4_same(gbtreekey8, gbtreekey8, internal),
    function 1(integer, integer) gbt_int4_consistent(internal, integer, smallint, oid, internal),
    function 9(integer, integer) gbt_int4_fetch(internal),
    function 2(integer, integer) gbt_int4_union(internal, internal),
    function 8(integer, integer) gbt_int4_distance(internal, integer, smallint, oid, internal),
    function 3(integer, integer) gbt_int4_compress(internal),
    function 4(integer, integer) gbt_decompress(internal),
    function 5(integer, integer) gbt_int4_penalty(internal, internal, internal),
    function 6(integer, integer) gbt_int4_picksplit(internal, internal);

alter operator family gist_int4_ops using gist owner to m1user1_04;

create operator class gist_int4_ops default for type integer using gist as storage gbtreekey8 function 6(integer, integer) gbt_int4_picksplit(internal, internal),
	function 7(integer, integer) gbt_int4_same(gbtreekey8, gbtreekey8, internal),
	function 2(integer, integer) gbt_int4_union(internal, internal),
	function 5(integer, integer) gbt_int4_penalty(internal, internal, internal),
	function 1(integer, integer) gbt_int4_consistent(internal, integer, smallint, oid, internal);

alter operator class gist_int4_ops using gist owner to m1user1_04;

create operator family gist_int8_ops using gist;

alter operator family gist_int8_ops using gist add
    operator 1 <(bigint,bigint),
    operator 2 <=(bigint,bigint),
    operator 3 =(bigint,bigint),
    operator 4 >=(bigint,bigint),
    operator 5 >(bigint,bigint),
    operator 6 <>(bigint,bigint),
    operator 15 <->(bigint, bigint) for order by integer_ops,
    function 1(bigint, bigint) gbt_int8_consistent(internal, bigint, smallint, oid, internal),
    function 2(bigint, bigint) gbt_int8_union(internal, internal),
    function 3(bigint, bigint) gbt_int8_compress(internal),
    function 4(bigint, bigint) gbt_decompress(internal),
    function 5(bigint, bigint) gbt_int8_penalty(internal, internal, internal),
    function 6(bigint, bigint) gbt_int8_picksplit(internal, internal),
    function 7(bigint, bigint) gbt_int8_same(gbtreekey16, gbtreekey16, internal),
    function 8(bigint, bigint) gbt_int8_distance(internal, bigint, smallint, oid, internal),
    function 9(bigint, bigint) gbt_int8_fetch(internal);

alter operator family gist_int8_ops using gist owner to m1user1_04;

create operator class gist_int8_ops default for type bigint using gist as storage gbtreekey16 function 5(bigint, bigint) gbt_int8_penalty(internal, internal, internal),
	function 1(bigint, bigint) gbt_int8_consistent(internal, bigint, smallint, oid, internal),
	function 7(bigint, bigint) gbt_int8_same(gbtreekey16, gbtreekey16, internal),
	function 6(bigint, bigint) gbt_int8_picksplit(internal, internal),
	function 2(bigint, bigint) gbt_int8_union(internal, internal);

alter operator class gist_int8_ops using gist owner to m1user1_04;

create operator family gist_float4_ops using gist;

alter operator family gist_float4_ops using gist add
    operator 1 <(real,real),
    operator 2 <=(real,real),
    operator 3 =(real,real),
    operator 4 >=(real,real),
    operator 5 >(real,real),
    operator 6 <>(real,real),
    operator 15 <->(real, real) for order by float_ops,
    function 9(real, real) gbt_float4_fetch(internal),
    function 2(real, real) gbt_float4_union(internal, internal),
    function 6(real, real) gbt_float4_picksplit(internal, internal),
    function 3(real, real) gbt_float4_compress(internal),
    function 8(real, real) gbt_float4_distance(internal, real, smallint, oid, internal),
    function 7(real, real) gbt_float4_same(gbtreekey8, gbtreekey8, internal),
    function 4(real, real) gbt_decompress(internal),
    function 1(real, real) gbt_float4_consistent(internal, real, smallint, oid, internal),
    function 5(real, real) gbt_float4_penalty(internal, internal, internal);

alter operator family gist_float4_ops using gist owner to m1user1_04;

create operator class gist_float4_ops default for type real using gist as storage gbtreekey8 function 7(real, real) gbt_float4_same(gbtreekey8, gbtreekey8, internal),
	function 6(real, real) gbt_float4_picksplit(internal, internal),
	function 5(real, real) gbt_float4_penalty(internal, internal, internal),
	function 1(real, real) gbt_float4_consistent(internal, real, smallint, oid, internal),
	function 2(real, real) gbt_float4_union(internal, internal);

alter operator class gist_float4_ops using gist owner to m1user1_04;

create operator family gist_float8_ops using gist;

alter operator family gist_float8_ops using gist add
    operator 1 <(double precision,double precision),
    operator 2 <=(double precision,double precision),
    operator 3 =(double precision,double precision),
    operator 4 >=(double precision,double precision),
    operator 5 >(double precision,double precision),
    operator 6 <>(double precision,double precision),
    operator 15 <->(double precision, double precision) for order by float_ops,
    function 4(double precision, double precision) gbt_decompress(internal),
    function 3(double precision, double precision) gbt_float8_compress(internal),
    function 2(double precision, double precision) gbt_float8_union(internal, internal),
    function 1(double precision, double precision) gbt_float8_consistent(internal, double precision, smallint, oid, internal),
    function 9(double precision, double precision) gbt_float8_fetch(internal),
    function 8(double precision, double precision) gbt_float8_distance(internal, double precision, smallint, oid, internal),
    function 7(double precision, double precision) gbt_float8_same(gbtreekey16, gbtreekey16, internal),
    function 6(double precision, double precision) gbt_float8_picksplit(internal, internal),
    function 5(double precision, double precision) gbt_float8_penalty(internal, internal, internal);

alter operator family gist_float8_ops using gist owner to m1user1_04;

create operator class gist_float8_ops default for type double precision using gist as storage gbtreekey16 function 1(double precision, double precision) gbt_float8_consistent(internal, double precision, smallint, oid, internal),
	function 7(double precision, double precision) gbt_float8_same(gbtreekey16, gbtreekey16, internal),
	function 5(double precision, double precision) gbt_float8_penalty(internal, internal, internal),
	function 6(double precision, double precision) gbt_float8_picksplit(internal, internal),
	function 2(double precision, double precision) gbt_float8_union(internal, internal);

alter operator class gist_float8_ops using gist owner to m1user1_04;

create operator family gist_timestamp_ops using gist;

alter operator family gist_timestamp_ops using gist add
    operator 1 <(timestamp without time zone,timestamp without time zone),
    operator 2 <=(timestamp without time zone,timestamp without time zone),
    operator 3 =(timestamp without time zone,timestamp without time zone),
    operator 4 >=(timestamp without time zone,timestamp without time zone),
    operator 5 >(timestamp without time zone,timestamp without time zone),
    operator 6 <>(timestamp without time zone,timestamp without time zone),
    operator 15 <->(timestamp, timestamp) for order by interval_ops,
    function 8(timestamp without time zone, timestamp without time zone) gbt_ts_distance(internal, timestamp, smallint, oid, internal),
    function 2(timestamp without time zone, timestamp without time zone) gbt_ts_union(internal, internal),
    function 3(timestamp without time zone, timestamp without time zone) gbt_ts_compress(internal),
    function 4(timestamp without time zone, timestamp without time zone) gbt_decompress(internal),
    function 5(timestamp without time zone, timestamp without time zone) gbt_ts_penalty(internal, internal, internal),
    function 6(timestamp without time zone, timestamp without time zone) gbt_ts_picksplit(internal, internal),
    function 7(timestamp without time zone, timestamp without time zone) gbt_ts_same(gbtreekey16, gbtreekey16, internal),
    function 1(timestamp without time zone, timestamp without time zone) gbt_ts_consistent(internal, timestamp, smallint, oid, internal),
    function 9(timestamp without time zone, timestamp without time zone) gbt_ts_fetch(internal);

alter operator family gist_timestamp_ops using gist owner to m1user1_04;

create operator class gist_timestamp_ops default for type timestamp without time zone using gist as storage gbtreekey16 function 5(timestamp without time zone, timestamp without time zone) gbt_ts_penalty(internal, internal, internal),
	function 1(timestamp without time zone, timestamp without time zone) gbt_ts_consistent(internal, timestamp, smallint, oid, internal),
	function 7(timestamp without time zone, timestamp without time zone) gbt_ts_same(gbtreekey16, gbtreekey16, internal),
	function 6(timestamp without time zone, timestamp without time zone) gbt_ts_picksplit(internal, internal),
	function 2(timestamp without time zone, timestamp without time zone) gbt_ts_union(internal, internal);

alter operator class gist_timestamp_ops using gist owner to m1user1_04;

create operator family gist_timestamptz_ops using gist;

alter operator family gist_timestamptz_ops using gist add
    operator 1 <(timestamp with time zone,timestamp with time zone),
    operator 2 <=(timestamp with time zone,timestamp with time zone),
    operator 3 =(timestamp with time zone,timestamp with time zone),
    operator 4 >=(timestamp with time zone,timestamp with time zone),
    operator 5 >(timestamp with time zone,timestamp with time zone),
    operator 6 <>(timestamp with time zone,timestamp with time zone),
    operator 15 <->(timestamp with time zone, timestamp with time zone) for order by interval_ops,
    function 4(timestamp with time zone, timestamp with time zone) gbt_decompress(internal),
    function 7(timestamp with time zone, timestamp with time zone) gbt_ts_same(gbtreekey16, gbtreekey16, internal),
    function 3(timestamp with time zone, timestamp with time zone) gbt_tstz_compress(internal),
    function 2(timestamp with time zone, timestamp with time zone) gbt_ts_union(internal, internal),
    function 1(timestamp with time zone, timestamp with time zone) gbt_tstz_consistent(internal, timestamp with time zone, smallint, oid, internal),
    function 8(timestamp with time zone, timestamp with time zone) gbt_tstz_distance(internal, timestamp with time zone, smallint, oid, internal),
    function 9(timestamp with time zone, timestamp with time zone) gbt_ts_fetch(internal),
    function 5(timestamp with time zone, timestamp with time zone) gbt_ts_penalty(internal, internal, internal),
    function 6(timestamp with time zone, timestamp with time zone) gbt_ts_picksplit(internal, internal);

alter operator family gist_timestamptz_ops using gist owner to m1user1_04;

create operator class gist_timestamptz_ops default for type timestamp with time zone using gist as storage gbtreekey16 function 1(timestamp with time zone, timestamp with time zone) gbt_tstz_consistent(internal, timestamp with time zone, smallint, oid, internal),
	function 7(timestamp with time zone, timestamp with time zone) gbt_ts_same(gbtreekey16, gbtreekey16, internal),
	function 6(timestamp with time zone, timestamp with time zone) gbt_ts_picksplit(internal, internal),
	function 5(timestamp with time zone, timestamp with time zone) gbt_ts_penalty(internal, internal, internal),
	function 2(timestamp with time zone, timestamp with time zone) gbt_ts_union(internal, internal);

alter operator class gist_timestamptz_ops using gist owner to m1user1_04;

create operator family gist_time_ops using gist;

alter operator family gist_time_ops using gist add
    operator 1 <(time without time zone,time without time zone),
    operator 2 <=(time without time zone,time without time zone),
    operator 3 =(time without time zone,time without time zone),
    operator 4 >=(time without time zone,time without time zone),
    operator 5 >(time without time zone,time without time zone),
    operator 6 <>(time without time zone,time without time zone),
    operator 15 <->(time, time) for order by interval_ops,
    function 2(time without time zone, time without time zone) gbt_time_union(internal, internal),
    function 9(time without time zone, time without time zone) gbt_time_fetch(internal),
    function 8(time without time zone, time without time zone) gbt_time_distance(internal, time, smallint, oid, internal),
    function 7(time without time zone, time without time zone) gbt_time_same(gbtreekey16, gbtreekey16, internal),
    function 6(time without time zone, time without time zone) gbt_time_picksplit(internal, internal),
    function 5(time without time zone, time without time zone) gbt_time_penalty(internal, internal, internal),
    function 4(time without time zone, time without time zone) gbt_decompress(internal),
    function 3(time without time zone, time without time zone) gbt_time_compress(internal),
    function 1(time without time zone, time without time zone) gbt_time_consistent(internal, time, smallint, oid, internal);

alter operator family gist_time_ops using gist owner to m1user1_04;

create operator class gist_time_ops default for type time without time zone using gist as storage gbtreekey16 function 1(time without time zone, time without time zone) gbt_time_consistent(internal, time, smallint, oid, internal),
	function 6(time without time zone, time without time zone) gbt_time_picksplit(internal, internal),
	function 7(time without time zone, time without time zone) gbt_time_same(gbtreekey16, gbtreekey16, internal),
	function 2(time without time zone, time without time zone) gbt_time_union(internal, internal),
	function 5(time without time zone, time without time zone) gbt_time_penalty(internal, internal, internal);

alter operator class gist_time_ops using gist owner to m1user1_04;

create operator family gist_timetz_ops using gist;

alter operator family gist_timetz_ops using gist add
    operator 1 <(time with time zone,time with time zone),
    operator 2 <=(time with time zone,time with time zone),
    operator 3 =(time with time zone,time with time zone),
    operator 4 >=(time with time zone,time with time zone),
    operator 5 >(time with time zone,time with time zone),
    operator 6 <>(time with time zone,time with time zone),
    function 1(time with time zone, time with time zone) gbt_timetz_consistent(internal, time with time zone, smallint, oid, internal),
    function 3(time with time zone, time with time zone) gbt_timetz_compress(internal),
    function 4(time with time zone, time with time zone) gbt_decompress(internal),
    function 5(time with time zone, time with time zone) gbt_time_penalty(internal, internal, internal),
    function 7(time with time zone, time with time zone) gbt_time_same(gbtreekey16, gbtreekey16, internal),
    function 2(time with time zone, time with time zone) gbt_time_union(internal, internal),
    function 6(time with time zone, time with time zone) gbt_time_picksplit(internal, internal);

alter operator family gist_timetz_ops using gist owner to m1user1_04;

create operator class gist_timetz_ops default for type time with time zone using gist as storage gbtreekey16 function 1(time with time zone, time with time zone) gbt_timetz_consistent(internal, time with time zone, smallint, oid, internal),
	function 2(time with time zone, time with time zone) gbt_time_union(internal, internal),
	function 5(time with time zone, time with time zone) gbt_time_penalty(internal, internal, internal),
	function 6(time with time zone, time with time zone) gbt_time_picksplit(internal, internal),
	function 7(time with time zone, time with time zone) gbt_time_same(gbtreekey16, gbtreekey16, internal);

alter operator class gist_timetz_ops using gist owner to m1user1_04;

create operator family gist_date_ops using gist;

alter operator family gist_date_ops using gist add
    operator 1 <(date,date),
    operator 2 <=(date,date),
    operator 3 =(date,date),
    operator 4 >=(date,date),
    operator 5 >(date,date),
    operator 6 <>(date,date),
    operator 15 <->(date, date) for order by integer_ops,
    function 5(date, date) gbt_date_penalty(internal, internal, internal),
    function 3(date, date) gbt_date_compress(internal),
    function 6(date, date) gbt_date_picksplit(internal, internal),
    function 7(date, date) gbt_date_same(gbtreekey8, gbtreekey8, internal),
    function 2(date, date) gbt_date_union(internal, internal),
    function 9(date, date) gbt_date_fetch(internal),
    function 8(date, date) gbt_date_distance(internal, date, smallint, oid, internal),
    function 4(date, date) gbt_decompress(internal),
    function 1(date, date) gbt_date_consistent(internal, date, smallint, oid, internal);

alter operator family gist_date_ops using gist owner to m1user1_04;

create operator class gist_date_ops default for type date using gist as storage gbtreekey8 function 2(date, date) gbt_date_union(internal, internal),
	function 5(date, date) gbt_date_penalty(internal, internal, internal),
	function 6(date, date) gbt_date_picksplit(internal, internal),
	function 7(date, date) gbt_date_same(gbtreekey8, gbtreekey8, internal),
	function 1(date, date) gbt_date_consistent(internal, date, smallint, oid, internal);

alter operator class gist_date_ops using gist owner to m1user1_04;

create operator family gist_interval_ops using gist;

alter operator family gist_interval_ops using gist add
    operator 1 <(interval,interval),
    operator 2 <=(interval,interval),
    operator 3 =(interval,interval),
    operator 4 >=(interval,interval),
    operator 5 >(interval,interval),
    operator 6 <>(interval,interval),
    operator 15 <->(interval, interval) for order by interval_ops,
    function 3(interval, interval) gbt_intv_compress(internal),
    function 5(interval, interval) gbt_intv_penalty(internal, internal, internal),
    function 6(interval, interval) gbt_intv_picksplit(internal, internal),
    function 7(interval, interval) gbt_intv_same(gbtreekey32, gbtreekey32, internal),
    function 2(interval, interval) gbt_intv_union(internal, internal),
    function 8(interval, interval) gbt_intv_distance(internal, interval, smallint, oid, internal),
    function 1(interval, interval) gbt_intv_consistent(internal, interval, smallint, oid, internal),
    function 9(interval, interval) gbt_intv_fetch(internal),
    function 4(interval, interval) gbt_intv_decompress(internal);

alter operator family gist_interval_ops using gist owner to m1user1_04;

create operator class gist_interval_ops default for type interval using gist as storage gbtreekey32 function 2(interval, interval) gbt_intv_union(internal, internal),
	function 1(interval, interval) gbt_intv_consistent(internal, interval, smallint, oid, internal),
	function 5(interval, interval) gbt_intv_penalty(internal, internal, internal),
	function 7(interval, interval) gbt_intv_same(gbtreekey32, gbtreekey32, internal),
	function 6(interval, interval) gbt_intv_picksplit(internal, internal);

alter operator class gist_interval_ops using gist owner to m1user1_04;

create operator family gist_cash_ops using gist;

alter operator family gist_cash_ops using gist add
    operator 1 <(money,money),
    operator 2 <=(money,money),
    operator 3 =(money,money),
    operator 4 >=(money,money),
    operator 5 >(money,money),
    operator 6 <>(money,money),
    operator 15 <->(money, money) for order by money_ops,
    function 4(money, money) gbt_decompress(internal),
    function 9(money, money) gbt_cash_fetch(internal),
    function 8(money, money) gbt_cash_distance(internal, money, smallint, oid, internal),
    function 7(money, money) gbt_cash_same(gbtreekey16, gbtreekey16, internal),
    function 6(money, money) gbt_cash_picksplit(internal, internal),
    function 5(money, money) gbt_cash_penalty(internal, internal, internal),
    function 3(money, money) gbt_cash_compress(internal),
    function 2(money, money) gbt_cash_union(internal, internal),
    function 1(money, money) gbt_cash_consistent(internal, money, smallint, oid, internal);

alter operator family gist_cash_ops using gist owner to m1user1_04;

create operator class gist_cash_ops default for type money using gist as storage gbtreekey16 function 1(money, money) gbt_cash_consistent(internal, money, smallint, oid, internal),
	function 7(money, money) gbt_cash_same(gbtreekey16, gbtreekey16, internal),
	function 6(money, money) gbt_cash_picksplit(internal, internal),
	function 5(money, money) gbt_cash_penalty(internal, internal, internal),
	function 2(money, money) gbt_cash_union(internal, internal);

alter operator class gist_cash_ops using gist owner to m1user1_04;

create operator family gist_macaddr_ops using gist;

alter operator family gist_macaddr_ops using gist add
    operator 1 <(macaddr,macaddr),
    operator 2 <=(macaddr,macaddr),
    operator 3 =(macaddr,macaddr),
    operator 4 >=(macaddr,macaddr),
    operator 5 >(macaddr,macaddr),
    operator 6 <>(macaddr,macaddr),
    function 9(macaddr, macaddr) gbt_macad_fetch(internal),
    function 3(macaddr, macaddr) gbt_macad_compress(internal),
    function 4(macaddr, macaddr) gbt_decompress(internal),
    function 5(macaddr, macaddr) gbt_macad_penalty(internal, internal, internal),
    function 6(macaddr, macaddr) gbt_macad_picksplit(internal, internal),
    function 1(macaddr, macaddr) gbt_macad_consistent(internal, macaddr, smallint, oid, internal),
    function 7(macaddr, macaddr) gbt_macad_same(gbtreekey16, gbtreekey16, internal),
    function 2(macaddr, macaddr) gbt_macad_union(internal, internal);

alter operator family gist_macaddr_ops using gist owner to m1user1_04;

create operator class gist_macaddr_ops default for type macaddr using gist as storage gbtreekey16 function 2(macaddr, macaddr) gbt_macad_union(internal, internal),
	function 7(macaddr, macaddr) gbt_macad_same(gbtreekey16, gbtreekey16, internal),
	function 6(macaddr, macaddr) gbt_macad_picksplit(internal, internal),
	function 5(macaddr, macaddr) gbt_macad_penalty(internal, internal, internal),
	function 1(macaddr, macaddr) gbt_macad_consistent(internal, macaddr, smallint, oid, internal);

alter operator class gist_macaddr_ops using gist owner to m1user1_04;

create operator family gist_text_ops using gist;

alter operator family gist_text_ops using gist add
    operator 1 <(text,text),
    operator 2 <=(text,text),
    operator 3 =(text,text),
    operator 4 >=(text,text),
    operator 5 >(text,text),
    operator 6 <>(text,text),
    function 4(text, text) gbt_var_decompress(internal),
    function 2(text, text) gbt_text_union(internal, internal),
    function 1(text, text) gbt_text_consistent(internal, text, smallint, oid, internal),
    function 3(text, text) gbt_text_compress(internal),
    function 9(text, text) gbt_var_fetch(internal),
    function 7(text, text) gbt_text_same(gbtreekey_var, gbtreekey_var, internal),
    function 6(text, text) gbt_text_picksplit(internal, internal),
    function 5(text, text) gbt_text_penalty(internal, internal, internal);

alter operator family gist_text_ops using gist owner to m1user1_04;

create operator class gist_text_ops default for type text using gist as storage gbtreekey_var function 1(text, text) gbt_text_consistent(internal, text, smallint, oid, internal),
	function 7(text, text) gbt_text_same(gbtreekey_var, gbtreekey_var, internal),
	function 6(text, text) gbt_text_picksplit(internal, internal),
	function 5(text, text) gbt_text_penalty(internal, internal, internal),
	function 2(text, text) gbt_text_union(internal, internal);

alter operator class gist_text_ops using gist owner to m1user1_04;

create operator family gist_bpchar_ops using gist;

alter operator family gist_bpchar_ops using gist add
    operator 1 <(character,character),
    operator 2 <=(character,character),
    operator 3 =(character,character),
    operator 4 >=(character,character),
    operator 5 >(character,character),
    operator 6 <>(character,character),
    function 9(character, character) gbt_var_fetch(internal),
    function 1(character, character) gbt_bpchar_consistent(internal, char, smallint, oid, internal),
    function 2(character, character) gbt_text_union(internal, internal),
    function 3(character, character) gbt_bpchar_compress(internal),
    function 4(character, character) gbt_var_decompress(internal),
    function 5(character, character) gbt_text_penalty(internal, internal, internal),
    function 6(character, character) gbt_text_picksplit(internal, internal),
    function 7(character, character) gbt_text_same(gbtreekey_var, gbtreekey_var, internal);

alter operator family gist_bpchar_ops using gist owner to m1user1_04;

create operator class gist_bpchar_ops default for type character using gist as storage gbtreekey_var function 6(character, character) gbt_text_picksplit(internal, internal),
	function 7(character, character) gbt_text_same(gbtreekey_var, gbtreekey_var, internal),
	function 2(character, character) gbt_text_union(internal, internal),
	function 5(character, character) gbt_text_penalty(internal, internal, internal),
	function 1(character, character) gbt_bpchar_consistent(internal, char, smallint, oid, internal);

alter operator class gist_bpchar_ops using gist owner to m1user1_04;

create operator family gist_bytea_ops using gist;

alter operator family gist_bytea_ops using gist add
    operator 1 <(bytea,bytea),
    operator 2 <=(bytea,bytea),
    operator 3 =(bytea,bytea),
    operator 4 >=(bytea,bytea),
    operator 5 >(bytea,bytea),
    operator 6 <>(bytea,bytea),
    function 4(bytea, bytea) gbt_var_decompress(internal),
    function 3(bytea, bytea) gbt_bytea_compress(internal),
    function 2(bytea, bytea) gbt_bytea_union(internal, internal),
    function 1(bytea, bytea) gbt_bytea_consistent(internal, bytea, smallint, oid, internal),
    function 9(bytea, bytea) gbt_var_fetch(internal),
    function 7(bytea, bytea) gbt_bytea_same(gbtreekey_var, gbtreekey_var, internal),
    function 6(bytea, bytea) gbt_bytea_picksplit(internal, internal),
    function 5(bytea, bytea) gbt_bytea_penalty(internal, internal, internal);

alter operator family gist_bytea_ops using gist owner to m1user1_04;

create operator class gist_bytea_ops default for type bytea using gist as storage gbtreekey_var function 6(bytea, bytea) gbt_bytea_picksplit(internal, internal),
	function 7(bytea, bytea) gbt_bytea_same(gbtreekey_var, gbtreekey_var, internal),
	function 1(bytea, bytea) gbt_bytea_consistent(internal, bytea, smallint, oid, internal),
	function 2(bytea, bytea) gbt_bytea_union(internal, internal),
	function 5(bytea, bytea) gbt_bytea_penalty(internal, internal, internal);

alter operator class gist_bytea_ops using gist owner to m1user1_04;

create operator family gist_numeric_ops using gist;

alter operator family gist_numeric_ops using gist add
    operator 1 <(numeric,numeric),
    operator 2 <=(numeric,numeric),
    operator 3 =(numeric,numeric),
    operator 4 >=(numeric,numeric),
    operator 5 >(numeric,numeric),
    operator 6 <>(numeric,numeric),
    function 4(numeric, numeric) gbt_var_decompress(internal),
    function 1(numeric, numeric) gbt_numeric_consistent(internal, numeric, smallint, oid, internal),
    function 3(numeric, numeric) gbt_numeric_compress(internal),
    function 2(numeric, numeric) gbt_numeric_union(internal, internal),
    function 9(numeric, numeric) gbt_var_fetch(internal),
    function 7(numeric, numeric) gbt_numeric_same(gbtreekey_var, gbtreekey_var, internal),
    function 6(numeric, numeric) gbt_numeric_picksplit(internal, internal),
    function 5(numeric, numeric) gbt_numeric_penalty(internal, internal, internal);

alter operator family gist_numeric_ops using gist owner to m1user1_04;

create operator class gist_numeric_ops default for type numeric using gist as storage gbtreekey_var function 1(numeric, numeric) gbt_numeric_consistent(internal, numeric, smallint, oid, internal),
	function 7(numeric, numeric) gbt_numeric_same(gbtreekey_var, gbtreekey_var, internal),
	function 6(numeric, numeric) gbt_numeric_picksplit(internal, internal),
	function 5(numeric, numeric) gbt_numeric_penalty(internal, internal, internal),
	function 2(numeric, numeric) gbt_numeric_union(internal, internal);

alter operator class gist_numeric_ops using gist owner to m1user1_04;

create operator family gist_bit_ops using gist;

alter operator family gist_bit_ops using gist add
    operator 1 <(bit,bit),
    operator 2 <=(bit,bit),
    operator 3 =(bit,bit),
    operator 4 >=(bit,bit),
    operator 5 >(bit,bit),
    operator 6 <>(bit,bit),
    function 3(bit, bit) gbt_bit_compress(internal),
    function 4(bit, bit) gbt_var_decompress(internal),
    function 9(bit, bit) gbt_var_fetch(internal),
    function 1(bit, bit) gbt_bit_consistent(internal, bit, smallint, oid, internal),
    function 2(bit, bit) gbt_bit_union(internal, internal),
    function 5(bit, bit) gbt_bit_penalty(internal, internal, internal),
    function 7(bit, bit) gbt_bit_same(gbtreekey_var, gbtreekey_var, internal),
    function 6(bit, bit) gbt_bit_picksplit(internal, internal);

alter operator family gist_bit_ops using gist owner to m1user1_04;

create operator class gist_bit_ops default for type bit using gist as storage gbtreekey_var function 7(bit, bit) gbt_bit_same(gbtreekey_var, gbtreekey_var, internal),
	function 1(bit, bit) gbt_bit_consistent(internal, bit, smallint, oid, internal),
	function 2(bit, bit) gbt_bit_union(internal, internal),
	function 5(bit, bit) gbt_bit_penalty(internal, internal, internal),
	function 6(bit, bit) gbt_bit_picksplit(internal, internal);

alter operator class gist_bit_ops using gist owner to m1user1_04;

create operator family gist_vbit_ops using gist;

alter operator family gist_vbit_ops using gist add
    operator 1 <(bit varying,bit varying),
    operator 2 <=(bit varying,bit varying),
    operator 3 =(bit varying,bit varying),
    operator 4 >=(bit varying,bit varying),
    operator 5 >(bit varying,bit varying),
    operator 6 <>(bit varying,bit varying),
    function 7(bit varying, bit varying) gbt_bit_same(gbtreekey_var, gbtreekey_var, internal),
    function 9(bit varying, bit varying) gbt_var_fetch(internal),
    function 1(bit varying, bit varying) gbt_bit_consistent(internal, bit, smallint, oid, internal),
    function 3(bit varying, bit varying) gbt_bit_compress(internal),
    function 4(bit varying, bit varying) gbt_var_decompress(internal),
    function 5(bit varying, bit varying) gbt_bit_penalty(internal, internal, internal),
    function 6(bit varying, bit varying) gbt_bit_picksplit(internal, internal),
    function 2(bit varying, bit varying) gbt_bit_union(internal, internal);

alter operator family gist_vbit_ops using gist owner to m1user1_04;

create operator class gist_vbit_ops default for type bit varying using gist as storage gbtreekey_var function 7(bit varying, bit varying) gbt_bit_same(gbtreekey_var, gbtreekey_var, internal),
	function 5(bit varying, bit varying) gbt_bit_penalty(internal, internal, internal),
	function 1(bit varying, bit varying) gbt_bit_consistent(internal, bit, smallint, oid, internal),
	function 6(bit varying, bit varying) gbt_bit_picksplit(internal, internal),
	function 2(bit varying, bit varying) gbt_bit_union(internal, internal);

alter operator class gist_vbit_ops using gist owner to m1user1_04;

create operator family gist_inet_ops using gist;

alter operator family gist_inet_ops using gist add
    operator 1 <(inet,inet),
    operator 2 <=(inet,inet),
    operator 3 =(inet,inet),
    operator 4 >=(inet,inet),
    operator 5 >(inet,inet),
    operator 6 <>(inet,inet),
    function 4(inet, inet) gbt_decompress(internal),
    function 6(inet, inet) gbt_inet_picksplit(internal, internal),
    function 7(inet, inet) gbt_inet_same(gbtreekey16, gbtreekey16, internal),
    function 2(inet, inet) gbt_inet_union(internal, internal),
    function 1(inet, inet) gbt_inet_consistent(internal, inet, smallint, oid, internal),
    function 3(inet, inet) gbt_inet_compress(internal),
    function 5(inet, inet) gbt_inet_penalty(internal, internal, internal);

alter operator family gist_inet_ops using gist owner to m1user1_04;

create operator class gist_inet_ops default for type inet using gist as storage gbtreekey16 function 2(inet, inet) gbt_inet_union(internal, internal),
	function 7(inet, inet) gbt_inet_same(gbtreekey16, gbtreekey16, internal),
	function 6(inet, inet) gbt_inet_picksplit(internal, internal),
	function 5(inet, inet) gbt_inet_penalty(internal, internal, internal),
	function 1(inet, inet) gbt_inet_consistent(internal, inet, smallint, oid, internal);

alter operator class gist_inet_ops using gist owner to m1user1_04;

create operator family gist_cidr_ops using gist;

alter operator family gist_cidr_ops using gist add
    operator 1 <(inet,inet),
    operator 2 <=(inet,inet),
    operator 3 =(inet,inet),
    operator 4 >=(inet,inet),
    operator 5 >(inet,inet),
    operator 6 <>(inet,inet),
    function 7(cidr, cidr) gbt_inet_same(gbtreekey16, gbtreekey16, internal),
    function 1(cidr, cidr) gbt_inet_consistent(internal, inet, smallint, oid, internal),
    function 2(cidr, cidr) gbt_inet_union(internal, internal),
    function 3(cidr, cidr) gbt_inet_compress(internal),
    function 4(cidr, cidr) gbt_decompress(internal),
    function 5(cidr, cidr) gbt_inet_penalty(internal, internal, internal),
    function 6(cidr, cidr) gbt_inet_picksplit(internal, internal);

alter operator family gist_cidr_ops using gist owner to m1user1_04;

create operator class gist_cidr_ops default for type cidr using gist as storage gbtreekey16 function 2(cidr, cidr) gbt_inet_union(internal, internal),
	function 1(cidr, cidr) gbt_inet_consistent(internal, inet, smallint, oid, internal),
	function 7(cidr, cidr) gbt_inet_same(gbtreekey16, gbtreekey16, internal),
	function 6(cidr, cidr) gbt_inet_picksplit(internal, internal),
	function 5(cidr, cidr) gbt_inet_penalty(internal, internal, internal);

alter operator class gist_cidr_ops using gist owner to m1user1_04;

create operator family gist_uuid_ops using gist;

alter operator family gist_uuid_ops using gist add
    operator 1 <(uuid,uuid),
    operator 2 <=(uuid,uuid),
    operator 3 =(uuid,uuid),
    operator 4 >=(uuid,uuid),
    operator 5 >(uuid,uuid),
    operator 6 <>(uuid,uuid),
    function 4(uuid, uuid) gbt_decompress(internal),
    function 5(uuid, uuid) gbt_uuid_penalty(internal, internal, internal),
    function 9(uuid, uuid) gbt_uuid_fetch(internal),
    function 7(uuid, uuid) gbt_uuid_same(gbtreekey32, gbtreekey32, internal),
    function 1(uuid, uuid) gbt_uuid_consistent(internal, uuid, smallint, oid, internal),
    function 2(uuid, uuid) gbt_uuid_union(internal, internal),
    function 3(uuid, uuid) gbt_uuid_compress(internal),
    function 6(uuid, uuid) gbt_uuid_picksplit(internal, internal);

alter operator family gist_uuid_ops using gist owner to m1user1_04;

create operator class gist_uuid_ops default for type uuid using gist as storage gbtreekey32 function 2(uuid, uuid) gbt_uuid_union(internal, internal),
	function 5(uuid, uuid) gbt_uuid_penalty(internal, internal, internal),
	function 6(uuid, uuid) gbt_uuid_picksplit(internal, internal),
	function 7(uuid, uuid) gbt_uuid_same(gbtreekey32, gbtreekey32, internal),
	function 1(uuid, uuid) gbt_uuid_consistent(internal, uuid, smallint, oid, internal);

alter operator class gist_uuid_ops using gist owner to m1user1_04;

create operator family gist_macaddr8_ops using gist;

alter operator family gist_macaddr8_ops using gist add
    operator 1 <(macaddr8,macaddr8),
    operator 2 <=(macaddr8,macaddr8),
    operator 3 =(macaddr8,macaddr8),
    operator 4 >=(macaddr8,macaddr8),
    operator 5 >(macaddr8,macaddr8),
    operator 6 <>(macaddr8,macaddr8),
    function 9(macaddr8, macaddr8) gbt_macad8_fetch(internal),
    function 3(macaddr8, macaddr8) gbt_macad8_compress(internal),
    function 7(macaddr8, macaddr8) gbt_macad8_same(gbtreekey16, gbtreekey16, internal),
    function 4(macaddr8, macaddr8) gbt_decompress(internal),
    function 5(macaddr8, macaddr8) gbt_macad8_penalty(internal, internal, internal),
    function 2(macaddr8, macaddr8) gbt_macad8_union(internal, internal),
    function 6(macaddr8, macaddr8) gbt_macad8_picksplit(internal, internal),
    function 1(macaddr8, macaddr8) gbt_macad8_consistent(internal, macaddr8, smallint, oid, internal);

alter operator family gist_macaddr8_ops using gist owner to m1user1_04;

create operator class gist_macaddr8_ops default for type macaddr8 using gist as storage gbtreekey16 function 6(macaddr8, macaddr8) gbt_macad8_picksplit(internal, internal),
	function 5(macaddr8, macaddr8) gbt_macad8_penalty(internal, internal, internal),
	function 2(macaddr8, macaddr8) gbt_macad8_union(internal, internal),
	function 7(macaddr8, macaddr8) gbt_macad8_same(gbtreekey16, gbtreekey16, internal),
	function 1(macaddr8, macaddr8) gbt_macad8_consistent(internal, macaddr8, smallint, oid, internal);

alter operator class gist_macaddr8_ops using gist owner to m1user1_04;

create operator family gist_enum_ops using gist;

alter operator family gist_enum_ops using gist add
    operator 1 <(anyenum,anyenum),
    operator 2 <=(anyenum,anyenum),
    operator 3 =(anyenum,anyenum),
    operator 4 >=(anyenum,anyenum),
    operator 5 >(anyenum,anyenum),
    operator 6 <>(anyenum,anyenum),
    function 9(anyenum, anyenum) gbt_enum_fetch(internal),
    function 1(anyenum, anyenum) gbt_enum_consistent(internal, anyenum, smallint, oid, internal),
    function 2(anyenum, anyenum) gbt_enum_union(internal, internal),
    function 3(anyenum, anyenum) gbt_enum_compress(internal),
    function 4(anyenum, anyenum) gbt_decompress(internal),
    function 5(anyenum, anyenum) gbt_enum_penalty(internal, internal, internal),
    function 6(anyenum, anyenum) gbt_enum_picksplit(internal, internal),
    function 7(anyenum, anyenum) gbt_enum_same(gbtreekey8, gbtreekey8, internal);

alter operator family gist_enum_ops using gist owner to m1user1_04;

create operator class gist_enum_ops default for type anyenum using gist as storage gbtreekey8 function 6(anyenum, anyenum) gbt_enum_picksplit(internal, internal),
	function 7(anyenum, anyenum) gbt_enum_same(gbtreekey8, gbtreekey8, internal),
	function 2(anyenum, anyenum) gbt_enum_union(internal, internal),
	function 1(anyenum, anyenum) gbt_enum_consistent(internal, anyenum, smallint, oid, internal),
	function 5(anyenum, anyenum) gbt_enum_penalty(internal, internal, internal);

alter operator class gist_enum_ops using gist owner to m1user1_04;

create operator family gist_bool_ops using gist;

alter operator family gist_bool_ops using gist add
    operator 1 <(boolean,boolean),
    operator 2 <=(boolean,boolean),
    operator 3 =(boolean,boolean),
    operator 4 >=(boolean,boolean),
    operator 5 >(boolean,boolean),
    operator 6 <>(boolean,boolean),
    function 3(boolean, boolean) gbt_bool_compress(internal),
    function 4(boolean, boolean) gbt_decompress(internal),
    function 5(boolean, boolean) gbt_bool_penalty(internal, internal, internal),
    function 6(boolean, boolean) gbt_bool_picksplit(internal, internal),
    function 2(boolean, boolean) gbt_bool_union(internal, internal),
    function 7(boolean, boolean) gbt_bool_same(gbtreekey2, gbtreekey2, internal),
    function 1(boolean, boolean) gbt_bool_consistent(internal, boolean, smallint, oid, internal),
    function 9(boolean, boolean) gbt_bool_fetch(internal);

alter operator family gist_bool_ops using gist owner to m1user1_04;

create operator class gist_bool_ops default for type boolean using gist as storage gbtreekey2 function 5(boolean, boolean) gbt_bool_penalty(internal, internal, internal),
	function 6(boolean, boolean) gbt_bool_picksplit(internal, internal),
	function 7(boolean, boolean) gbt_bool_same(gbtreekey2, gbtreekey2, internal),
	function 1(boolean, boolean) gbt_bool_consistent(internal, boolean, smallint, oid, internal),
	function 2(boolean, boolean) gbt_bool_union(internal, internal);

alter operator class gist_bool_ops using gist owner to m1user1_04;

