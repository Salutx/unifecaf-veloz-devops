FROM nginx:alpine

# Copiar configuração customizada
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiar página HTML
COPY index.html /usr/share/nginx/html/

# Criar arquivo de dados JSON
RUN echo '{"produtos":[{"id":1,"nome":"Notebook Dell","quantidade":50,"reservado":5},{"id":2,"nome":"Mouse Logitech","quantidade":200,"reservado":10},{"id":3,"nome":"Teclado Mecânico","quantidade":100,"reservado":15}]}' > /usr/share/nginx/html/data.json

# Permissões para usuário não-root
RUN chown -R nginx:nginx /usr/share/nginx/html && \
  chown -R nginx:nginx /var/cache/nginx && \
  chown -R nginx:nginx /etc/nginx/conf.d && \
  touch /var/run/nginx.pid && \
  chown -R nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["nginx", "-g", "daemon off;"]