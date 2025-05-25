FROM nodered/node-red:latest

# Installer les modules nécessaires
USER root

# Installation des modules Node-RED
RUN npm install --prefix /usr/src/node-red \
    node-red-node-feedparser \
    node-red-contrib-fs

# Retour à l'utilisateur node-red
USER node-red

# Variables d'environnement
ENV TZ=Europe/Paris
ENV NODE_RED_ENABLE_PROJECTS=true

# Exposition du port
EXPOSE 1880

# Commande par défaut
CMD ["npm", "start"]