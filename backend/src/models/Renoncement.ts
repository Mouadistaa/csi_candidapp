import {RenoncementType} from "../enums/RenoncementType";

export class Renoncement {

    // attributs
    id!: number;                // PK
    candidatureId!: number;     // FK vers Candidature
    type!: RenoncementType;
    dateRenoncement!: Date;
    justification?: string;

    dateValidation?: Date;      // validation potentielle par l'enseignant

    // Constructeur
    constructor(init?: Partial<Renoncement>) {
        Object.assign(this, init);
    }
}
