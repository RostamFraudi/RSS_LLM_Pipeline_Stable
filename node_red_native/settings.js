/**
 * Node-RED Settings - RSS LLM Pipeline Native
 */

module.exports = {
    // Configuration de base
    uiPort: process.env.PORT || 18880,
    
    // Pas d'authentification pour dev local
    // adminAuth: require('./auth.js'),
    
    // Dossier de données
    userDir: './node_red_native/',
    
    // Modules externes autorisés
    functionExternalModules: true,
    
    // Logging
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
    },
    
    // Context global
    functionGlobalContext: {
        // Variables disponibles dans les functions
        LLM_SERVICE_URL: "http://localhost:15000"
    },
    
    // Editeur
    editorTheme: {
        projects: {
            enabled: false
        }
    }
};
