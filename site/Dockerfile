FROM node:22-alpine AS dependencies

WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM dependencies AS development
COPY . .
EXPOSE 3002
CMD ["node", "scripts/start-container.cjs"]

FROM dependencies AS production
COPY . .
RUN npm run build
ENV NODE_ENV=production
EXPOSE 3002
CMD ["npm", "run", "start", "--", "--hostname", "0.0.0.0", "--port", "3002"]
