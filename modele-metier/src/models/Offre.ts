import { OffreType } from "../enums/OffreType";
import { StatutValidationOffre } from "../enums/StatutValidationOffre";

export class Offre {

    // attributs
    id!: number;           // PK
    entrepriseId!: number;      // FK vers Entreprise

    type!: OffreType;           // ENUM
    titre!: string;
    description?: string;

    competences?: string;       // liste simple CSV ou libre
    localisationPays!: string;
    localisationVille!: string;

    dureeMois!: number;
    remuneration!: number;

    dateDebut!: Date;
    dateExpiration!: Date;
    dateSoumission!: Date;
    dateValidation?: Date;

    statutValidation: StatutValidationOffre = StatutValidationOffre.EN_ATTENTE;

    // Constructeur
    constructor(init?: Partial<Offre>) {
        Object.assign(this, init);
    }
}