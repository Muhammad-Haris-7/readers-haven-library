# ---------- Stage 1: builder (Node.js builds the static site) ----------
# Pinned Node image (no :latest), small Alpine variant. Named "builder" so stage 2 can copy from it.
FROM node:22-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy only the package files first so the npm ci layer is cached until dependencies change
COPY package*.json ./

# Install the exact dependency versions from package-lock.json
RUN npm ci

# Copy the website source and styles (COPY, not ADD)
COPY src/ ./src/
COPY styles/ ./styles/

# Build all pages from src/ into /app/dist with Parcel
RUN npm run build

# ---------- Stage 2: runtime (Nginx serves only the built files) ----------
# Pinned small Nginx image. Node.js and node_modules are NOT included here.
FROM nginx:1.27-alpine

# Copy the built static site from the builder stage into Nginx's web folder
COPY --from=builder /app/dist /usr/share/nginx/html

# Document that the container listens on port 80
EXPOSE 80

# Run Nginx in the foreground so the container stays running
CMD ["nginx", "-g", "daemon off;"]