export type NotificationType =
    | 'OFFRE_SOUMISE'
    | 'OFFRE_VALIDEE'
    | 'OFFRE_REFUSEE'
    | 'CANDIDATURE_RECUE'
    | 'CANDIDATURE_ACCEPTEE'
    | 'CANDIDATURE_REJETEE'
    | 'AFFECTATION_VALIDEE'
    | 'RC_VALIDEE'
    | 'RC_REFUSEE'
    | 'SYSTEME';

export interface Notification {
    notification_id: number;
    destinataire_id: number;
    type: NotificationType;
    titre: string;
    message: string;
    lien: string | null;
    entite_type: string | null;
    entite_id: number | null;
    lu: boolean;
    created_at: Date;
}

export interface NotificationCount {
    non_lues: number;
    total: number;
}
