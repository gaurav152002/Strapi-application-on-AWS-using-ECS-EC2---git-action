# Use Node 20 slim (Strapi v5 compatible)
FROM node:20-slim

# Install required dependencies for sqlite
RUN apt-get update && apt-get install -y \
    python3 \
    build-essential \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files first (better caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy rest of project
COPY . .

# Create uploads directory (IMPORTANT FIX)
RUN mkdir -p public/uploads

# Expose Strapi port
EXPOSE 1337

# Start Strapi
CMD ["npm", "run", "develop"]
