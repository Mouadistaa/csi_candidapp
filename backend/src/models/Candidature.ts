import { StatutCandidature } from "../enums/StatutCandidature";

export class Candidature {

    // attributs
    id!: number;                // PK
    offreId!: number;           // FK vers Offre
    etudiantId!: number;        // FK vers Etudiant

    dateCandidature!: Date;
    source?: string;

    statut: StatutCandidature = StatutCandidature.EN_ATTENTE;

    // Constructeur
    constructor(init?: Partial<Candidature>) {
        Object.assign(this, init);
    }
}