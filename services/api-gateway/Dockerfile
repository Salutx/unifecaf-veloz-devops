FROM nginx:alpine

# Copiar configuração customizada
COPY nginx.conf /etc/nginx/nginx.conf

# Copiar página HTML
COPY index.html /usr/share/nginx/html/

# Permissões para usuário não-root
RUN chown -R nginx:nginx /usr/share/nginx/html && \
  chown -R nginx:nginx /var/cache/nginx && \
  chown -R nginx:nginx /etc/nginx && \
  touch /var/run/nginx.pid && \
  chown -R nginx:nginx /var/run/nginx.pid && \
  mkdir -p /var/log/nginx && \
  chown -R nginx:nginx /var/log/nginx

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["nginx", "-g", "daemon off;"]