FROM nginx:1.25.4-alpine

# Prepare directories for non-root Nginx
RUN mkdir -p \
        /var/cache/nginx/client_temp \
        /var/cache/nginx/proxy_temp \
        /var/cache/nginx/fastcgi_temp \
        /var/cache/nginx/uwsgi_temp \
        /var/cache/nginx/scgi_temp \
        /var/run/nginx \
        /usr/share/nginx/html \
    && chown -R nginx:nginx \
        /var/cache/nginx \
        /var/run/nginx \
        /usr/share/nginx/html

# Use a non-root Nginx configuration
RUN sed -i 's|pid        /var/run/nginx.pid;|pid        /var/run/nginx/nginx.pid;|' /etc/nginx/nginx.conf \
    && sed -i '/^user[[:space:]]\+nginx;/d' /etc/nginx/nginx.conf

COPY --chown=root:root default.conf /etc/nginx/conf.d/default.conf
COPY --chown=nginx:nginx index.html /usr/share/nginx/html/index.html

EXPOSE 8080

HEALTHCHECK --interval=30s \
            --timeout=5s \
            --start-period=5s \
            --retries=3 \
            CMD wget --no-verbose --tries=1 \
                -O - \
                http://127.0.0.1:8080/ > /dev/null || exit 1

USER nginx

CMD ["nginx", "-g", "daemon off;"]
