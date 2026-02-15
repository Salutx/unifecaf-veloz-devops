FROM nginx:alpine

# Copiar configuração customizada
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiar página HTML
COPY index.html /usr/share/nginx/html/

# Criar arquivo de dados JSON
RUN echo '{"pedidos":[{"id":1,"cliente":"João Silva","total":2500.00,"status":"PAGO"},{"id":2,"cliente":"Maria Santos","total":150.00,"status":"PENDENTE"}]}' > /usr/share/nginx/html/data.json

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