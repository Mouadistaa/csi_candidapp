export class Etudiant {

    // attributs
    etudiantId!: number;      // PK
    utilisateurId!: number;   // FK vers Utilisateur

    nom!: string;
    prenom!: string;
    formation!: string;

    promo?: string;
    cvUrl?: string;

    enRecherche: boolean = false;
    profilVisible: boolean = false;

    // Constructeur
    constructor(init?: Partial<Etudiant>) {
        Object.assign(this, init);
    }
}
