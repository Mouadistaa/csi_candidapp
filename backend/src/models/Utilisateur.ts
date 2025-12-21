import { Role } from "../enums/Role";

export class Utilisateur {

    // attributs
    id!: number;      // PK
    email!: string;
    passwordHash!: string;
    role!: Role;
    actif: boolean = true;
    createdAt!: Date;

    // Constructeur
    constructor(init?: Partial<Utilisateur>) {
        Object.assign(this, init);
    }
}