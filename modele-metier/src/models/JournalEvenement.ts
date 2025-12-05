export class JournalEvenement {

    // attributs
    id!: BigInteger;               // PK (journalEvenementId côté BDD si tu préfères)
    utilisateurId?: number;    // FK vers Utilisateur (optionnel pour les événements système)

    type!: string;             // ex : "CONNEXION", "CREATION_OFFRE", "VALIDATION_AFFECTATION"
    payload!: JSON;          // résumé lisible de l’évènement

    dateEvenement!: Date;      // horodatage

    // Constructeur
    constructor(init?: Partial<JournalEvenement>) {
        Object.assign(this, init);
    }
}
