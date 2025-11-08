# syntax=docker/dockerfile:1.6
FROM node:20-alpine AS base
RUN apk add --no-cache openssl
WORKDIR /app
ENV NODE_ENV=production

FROM base AS deps
ENV NODE_ENV=development
# Install dependencies in a dedicated layer so they can be cached independently.
COPY package.json package-lock.json* ./
RUN npm install --include=dev

FROM deps AS build
# Compile TypeScript and generate the Prisma client in an isolated layer.
COPY tsconfig.json tsconfig.build.json .eslintrc.cjs ./
COPY prisma ./prisma
COPY src ./src
RUN npm run build
RUN npm run prisma:generate

FROM deps AS development
ENV NODE_ENV=development
# Copy the entire workspace for a full-featured development image.
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Generate Prisma Client for development runtime.
RUN npm run prisma:generate
EXPOSE 3000
CMD ["npm", "run", "dev"]

FROM base AS production
# Prepare the minimal runtime image with prebuilt artifacts only.
COPY package.json package-lock.json* ./
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY prisma ./prisma
# Generate Prisma Client for production runtime.
RUN npm run prisma:generate
RUN npm prune --omit=dev
EXPOSE 3000
CMD ["npm", "run", "start"]

