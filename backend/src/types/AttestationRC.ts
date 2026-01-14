import { StatutRC } from "../enums/StatutRC";

export interface AttestationRC {
    etudiant_id: number;
    statut: StatutRC;
    fichier_url: string;
    date_depot: Date;
    date_validation?: Date;
    date_expiration?: Date;
    est_expiree?: boolean;
    jours_restants?: number;
}
