# Select the base image for the container
FROM node

# Set the working directory inside the container
WORKDIR /app

# Copy the package.json and package-lock.json files to the container
COPY package.json /app

# Run the command to install the dependencies
RUN npm install

# Copy files from the host to the container
COPY . /app

# Expose the port that the application will run on
EXPOSE 80

# Use the command to start the server
CMD ["node", "server.js"]