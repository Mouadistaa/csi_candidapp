import { StatutRC } from "../enums/StatutRC";

export class AttestationRC {

    // attributs             // PK
    etudiantId!: number;       // FK vers Etudiant

    fichierUrl!: string;       // lien du fichier déposé
    dateDepot!: Date;

    statut: StatutRC = StatutRC.DEPOSEE;

    dateValidation?: Date;

    // Constructeur
    constructor(init?: Partial<AttestationRC>) {
        Object.assign(this, init);
    }
}
