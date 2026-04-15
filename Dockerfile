# Image de base officielle Nginx (section 3.3)
FROM nginx:alpine3.23

# Supprimer la page par défaut de Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copier les fichiers de l'application dans le répertoire Nginx
COPY index.html /usr/share/nginx/html/
COPY elements.html /usr/share/nginx/html/
COPY generic.html /usr/share/nginx/html/
COPY landing.html /usr/share/nginx/html/
COPY assets /usr/share/nginx/html/assets
COPY images /usr/share/nginx/html/images

# Exposer le port 80
EXPOSE 80

# Démarrer Nginx
CMD ["nginx", "-g", "daemon off;"]
