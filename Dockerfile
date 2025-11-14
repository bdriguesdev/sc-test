FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile --production

# Copy application files
COPY . .

# Set default environment variable
ENV SCRAPERS=*

# Run the application
CMD ["yarn", "start"]
