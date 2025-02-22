# Description: Dockerfile for the CloudRegionAPI Node.js API. Based on node 22 slim image.
FROM node:22-slim

# Create a directory for the app user
RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app

# Set the working directory to the app user's home directory
WORKDIR /home/node/app

# Copy the package.json and package-lock.json files to the container
COPY package*.json ./

# Switch to the node user
USER node

# Install production dependencies
RUN npm install --omit=dev

# copy the 'compiled' release folder to the container
COPY --chown=node:node ./release/ .

# Expose the port the app runs on
EXPOSE 3000

# Serve the app
CMD [ "node", "index.js" ]
