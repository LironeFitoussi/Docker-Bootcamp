# Dockerfile for a Node.js application

# Use the official Node.js image from Docker Hub
FROM node:latest

# Set the working directory in the container to /app
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package.json  /app

# Install dependencies
RUN npm install

# Copy the rest of the application code to the working directory
COPY . /app

# Expose the port the app runs on
EXPOSE 3000

# Run the application
CMD ["node", "server.js"]