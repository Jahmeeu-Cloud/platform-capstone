FROM nginx:1.25.4-alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

HEALTHCHECK --interval=30s \
            --timeout=5s \
            --start-period=5s \
            --retries=3 \
            CMD wget --no-verbose --tries=1 \
                -O - \
                http://127.0.0.1/ > /dev/null || exit 1

CMD ["nginx", "-g", "daemon off;"]
