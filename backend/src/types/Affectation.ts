export interface Affectation {
    id: number;
    offre_id: number;
    date_validation?: Date;
}

/**
 * Interface pour les candidatures en attente de validation (vue v_candidatures_a_valider)
 */
export interface CandidatureAValider {
    candidature_id: number;
    nom_etudiant: string;
    prenom_etudiant: string;
    titre_offre: string;
    nom_entreprise: string;
    date_debut_offre: Date | string;
    nom_groupe: string | null;
}

/**
 * Payload pour valider une candidature et créer une affectation
 */
export interface PayloadValidation {
    candidature_id: number;
}
