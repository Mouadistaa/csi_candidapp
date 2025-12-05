export class Entreprise {

    // attributs
    entrepriseId!: number;     // PK
    utilisateurId!: number;    // FK vers Utilisateur

    raisonSociale!: string;
    siret?: string;

    pays!: string;
    ville?: string;
    adresse?: string;

    siteWeb?: string;
    contactNom?: string;
    contactEmail?: string;

    // Constructeur
    constructor(init?: Partial<Entreprise>) {
        Object.assign(this, init);
    }
}