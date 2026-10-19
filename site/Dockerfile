FROM node:22-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci

EXPOSE 3002
CMD ["npm", "run", "dev", "--", "--webpack", "--hostname", "0.0.0.0", "--port", "3002"]
