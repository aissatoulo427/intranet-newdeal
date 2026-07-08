# Image v2 (canary) : repart de la v1 et ne remplace que index.html
# (le bandeau "VERSION 2" permet de distinguer visuellement v1 et v2).
FROM aichalo/intranet-newdeal:latest

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
