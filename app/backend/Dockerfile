# ---------- Build stage ----------
FROM node:20.11.0-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev


# ---------- Runtime stage ----------
FROM node:20.11.0-alpine

WORKDIR /app

# Create non-root application user
RUN addgroup -S appgroup -g 1001 && \
    adduser -S appuser -u 1001 -G appgroup

COPY --from=builder /app/node_modules ./node_modules
COPY --chown=appuser:appgroup . .

ENV NODE_ENV=production
ENV PORT=5000

EXPOSE 5000

USER appuser

HEALTHCHECK --interval=30s \
            --timeout=5s \
            --start-period=10s \
            --retries=3 \
            CMD wget --no-verbose --tries=1 \
                http://127.0.0.1:5000/health || exit 1

CMD ["node", "index.js"]
