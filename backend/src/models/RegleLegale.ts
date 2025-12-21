import { OffreType } from "../enums/OffreType";

export class RegleLegale {

    // attributs
    id!: number;                // PK

    typeContrat!: OffreType;      // stage / alternance / CDD
    pays!: string;              // ex : "FRANCE", "ALLEMAGNE"

    dureeMinMois?: number;
    dureeMaxMois?: number;

    remunerationMin!: number;
    unite!: string;
    dateEffet!: Date;
    dateFin?: Date;

    // Constructeur
    constructor(init?: Partial<RegleLegale>) {
        Object.assign(this, init);
    }
}