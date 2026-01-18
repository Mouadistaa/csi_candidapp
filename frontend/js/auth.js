/**
 * Gestion centralisée de l'authentification
 * Ce fichier gère : connexion, déconnexion, vérification de session, redirections
 */

let Auth = {
    // Clés de storage
    STORAGE_KEYS: {
        USER: 'user',
        TOKEN: 'token'
    },

    /**
     * Récupère l'utilisateur connecté (vérifie les deux storages)
     */
    getUser() {
        try {
            const sessionUser = sessionStorage.getItem(this.STORAGE_KEYS.USER);
            const localUser = localStorage.getItem(this.STORAGE_KEYS.USER);

            if (sessionUser) {
                return JSON.parse(sessionUser);
            }
            if (localUser) {
                // Synchroniser avec sessionStorage
                sessionStorage.setItem(this.STORAGE_KEYS.USER, localUser);
                return JSON.parse(localUser);
            }
            return null;
        } catch (e) {
            console.error('Erreur lecture user:', e);
            return null;
        }
    },

    /**
     * Récupère le token
     */
    getToken() {
        return localStorage.getItem(this.STORAGE_KEYS.TOKEN) || sessionStorage.getItem(this.STORAGE_KEYS.TOKEN);
    },

    /**
     * Vérifie si l'utilisateur est connecté
     */
    isLoggedIn() {
        const user = this.getUser();
        const token = this.getToken();
        return user !== null && token !== null;
    },

    /**
     * Sauvegarde les données de connexion
     */
    saveLogin(user, token) {
        const userStr = JSON.stringify(user);
        localStorage.setItem(this.STORAGE_KEYS.USER, userStr);
        localStorage.setItem(this.STORAGE_KEYS.TOKEN, token || 'session');
        sessionStorage.setItem(this.STORAGE_KEYS.USER, userStr);
        sessionStorage.setItem(this.STORAGE_KEYS.TOKEN, token || 'session');
    },

    /**
     * Nettoie TOUS les storages - déconnexion complète
     */
    clearAll() {
        // Nettoyer localStorage
        localStorage.removeItem(this.STORAGE_KEYS.USER);
        localStorage.removeItem(this.STORAGE_KEYS.TOKEN);

        // Nettoyer sessionStorage
        sessionStorage.removeItem(this.STORAGE_KEYS.USER);
        sessionStorage.removeItem(this.STORAGE_KEYS.TOKEN);

        // Nettoyer tout le reste au cas où
        localStorage.clear();
        sessionStorage.clear();
    },

    /**
     * Déconnexion et redirection vers login
     */
    logout(message = null) {
        this.clearAll();

        // Éviter les boucles : ne pas rediriger si déjà sur login
        if (window.location.pathname === '/login' || window.location.pathname === '/login.html') {
            return;
        }

        const url = message ? `/login?success=${encodeURIComponent(message)}` : '/login';
        window.location.href = url;
    },

    /**
     * Retourne l'URL du dashboard selon le rôle
     */
    getDashboardUrl(role) {
        switch (role) {
            case 'ADMIN':
                return '/admin/dashboard';
            case 'ENSEIGNANT':
                return '/enseignant/dashboard';
            case 'SECRETAIRE':
                return '/secretaire/dashboard';
            case 'ENTREPRISE':
                return '/dashboard/entreprise';
            case 'ETUDIANT':
            default:
                return '/profile';
        }
    },

    /**
     * Redirige vers le dashboard approprié si connecté
     * À utiliser sur login.html et accueil.html
     */
    redirectIfLoggedIn() {
        // Ne pas faire de redirection si on vient de se déconnecter (paramètre dans l'URL)
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.has('logout') || urlParams.has('success')) {
            return false;
        }

        const user = this.getUser();
        if (user && user.role) {
            const dashboardUrl = this.getDashboardUrl(user.role);

            // Éviter les boucles : ne pas rediriger vers la même page
            if (window.location.pathname !== dashboardUrl) {
                window.location.href = dashboardUrl;
                return true;
            }
        }
        return false;
    },

    /**
     * Vérifie que l'utilisateur est connecté et a le bon rôle
     * Redirige vers login si non connecté
     * @param {string|string[]} allowedRoles - Rôle(s) autorisé(s)
     */
    requireAuth(allowedRoles = null) {
        const user = this.getUser();

        if (!user) {
            this.logout();
            return null;
        }

        // Si des rôles spécifiques sont requis, vérifier
        if (allowedRoles) {
            const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];
            if (!roles.includes(user.role)) {
                // Mauvais rôle : rediriger vers le bon dashboard
                window.location.href = this.getDashboardUrl(user.role);
                return null;
            }
        }

        return user;
    },

    /**
     * Vérifie la session côté serveur (optionnel, pour plus de sécurité)
     */
    async verifySession() {
        try {
            const token = this.getToken();
            if (!token) return false;

            const res = await fetch('/api/auth/verify', {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (!res.ok) {
                // Token invalide : déconnecter
                this.clearAll();
                return false;
            }

            return true;
        } catch (e) {
            console.error('Erreur vérification session:', e);
            return false;
        }
    },

    /**
     * Initialise l'UI utilisateur (avatar, email, etc.)
     * @param {Object} selectors - IDs des éléments à remplir
     */
    initUserUI(selectors = {}) {
        const user = this.getUser();
        if (!user) return;

        const {
            initialEl = 'userInitial',
            emailEl = 'userEmailBadge',
            badgeEl = 'userBadge',
            nameEl = 'userName'
        } = selectors;

        const initial = (user.nom?.[0] || user.email?.[0] || '?').toUpperCase();

        const initElement = document.getElementById(initialEl);
        if (initElement) initElement.textContent = initial;

        const emailElement = document.getElementById(emailEl);
        if (emailElement) emailElement.textContent = user.email || '';

        const badgeElement = document.getElementById(badgeEl);
        if (badgeElement) badgeElement.classList.remove('hidden');

        const nameElement = document.getElementById(nameEl);
        if (nameElement) nameElement.textContent = user.nom || user.email || '';
    },

    /**
     * Attache le handler de déconnexion à un bouton
     * @param {string} buttonId - ID du bouton de déconnexion
     */
    attachLogoutHandler(buttonId = 'logoutBtn') {
        const btn = document.getElementById(buttonId);
        if (btn) {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                this.logout('Vous avez été déconnecté.');
            });
        }
    }
};

// Export pour utilisation globale
window.Auth = Auth;

