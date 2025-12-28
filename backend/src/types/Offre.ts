/**
 * Interface représentant une offre visible par les étudiants
 * Basée sur la vue SQL v_offres_visibles_etudiant
 */
export interface OffreVisible {
  offre_id: number;
  entreprise_nom: string;
  entreprise_site: string | null;
  entreprise_ville: string;
  titre: string;
  type: string;
  description: string;
  competences: string | null;
  localisation_ville: string;
  localisation_pays: string;
  duree_mois: number | null;
  remuneration: number | null;
  date_debut: Date;
  date_expiration: Date;
  est_expiree: boolean;
}
