# Select the base image for the container
FROM node:14

# Set the working directory inside the container
WORKDIR /app

# Copy the package.json file to the container
COPY package.json .

# Run the command to install the dependencies
RUN npm install

# Copy the rest of the application code to the container
COPY . .

# Create the temp directory for volume mounting
RUN mkdir -p /app/temp

# Expose the port that the application will run on
EXPOSE 80

# # Add a volume to the container
# VOLUME ["/app/feedback"]

# Use the command to start the server
CMD ["npm", "start"]