# Select the base image for the container
FROM node

# Set the working directory inside the container
WORKDIR /app

# Copy the package.json file to the container
COPY package.json .

# Run the command to install the dependencies
RUN npm install

# Copy the rest of the application code to the container
COPY . .

# Expose the port that the application will run on  
EXPOSE 80

# Environment variables
ENV MONGODB_USERNAME=root
ENV MONGODB_PASSWORD=secret


# Use the command to start the server
CMD ["npm", "start"]