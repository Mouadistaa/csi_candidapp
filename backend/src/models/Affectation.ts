export class Affectation {

    // attributs
    id!: number;                // PK
    offreId!: number;           // FK vers Candidature

    dateValidation?: Date;

    // Constructeur
    constructor(init?: Partial<Affectation>) {
        Object.assign(this, init);
    }
}
