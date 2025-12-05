export class Offre_RegleLegale {

    // attributs
    offreId!: number;         // FK vers Offre
    regleLegaleId!: number;   // FK vers RegleLegale

    // Constructeur
    constructor(init?: Partial<Offre_RegleLegale>) {
        Object.assign(this, init);
    }
}
