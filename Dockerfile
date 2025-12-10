# Description: Dockerfile for the CloudRegionAPI Node.js API. Based on node 22 slim image.
FROM node:24-slim

# Create a directory for the app user
RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app

# Set the working directory to the app user's home directory
WORKDIR /home/node/app

# Copy the package.json and package-lock.json files to the container
COPY --chown=node:node package*.json ./

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl

# Switch to the node user
USER node

# Install production dependencies
RUN npm install --omit=dev

# copy the 'compiled' release folder to the container
COPY --chown=node:node ./release/ ./release/

# save the build date to a text file
RUN echo -n `date +"%d-%B-%Y"` > ./release/build_date.txt

# Expose the port the app runs on
EXPOSE 80

# Serve the app
CMD [ "node", "./release/index.js" ]

HEALTHCHECK --interval=60s --timeout=3s --retries=2 CMD curl --fail http://localhost/health || exit 1