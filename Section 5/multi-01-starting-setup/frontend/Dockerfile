# Select the base image for the container
FROM node:20

# Set the working directory inside the container
WORKDIR /app

# Copy the package.json file to the container
COPY package.json .

# Run the command to install the dependencies
RUN npm install

# Copy the rest of the application code to the container
COPY . .

# Set the environment variable for the port
EXPOSE 3000

# Expose the port that the application will run on
CMD ["npm", "start"]
