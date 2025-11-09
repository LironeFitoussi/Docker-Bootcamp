<!-- First Run the docker container for mongodb -->
docker run --name mongodb --rm -d -p 27017:27017 mongo

<!-- Build the backend container -->
docker build -t goals-node .

<!-- Then run the backend container -->
docker run --name goals-backend --rm -d -p 80:80 goals-node 

<!-- Build the frontend container -->
docker build -t goals-react .

<!-- Then run the frontend container -->
docker run --name goals-frontend --rm -d -p 3000:3000 -it goals-react

<!-- WITH NETWORK -->

<!-- Create a network -->
docker network create goals-network

<!-- Run the mongodb container -->
docker run --name mongodb --rm -d -p 27017:27017 --network goals-net mongo

<!-- We must make sure to use the same network name in the backend container as in the mongodb container -->
<!-- Build the backend container -->
docker build -t goals-node .

<!-- Run the backend container -->
docker run --name goals-backend --rm -d -p 80:80 --network goals-net goals-node 

<!-- We must make sure to use the same network name in the frontend container as in the backend container -->
<!-- Build the frontend container -->
docker build -t goals-react .

<!-- Run the frontend container -->
docker run --name goals-frontend --rm -d -p 3000:3000 -it --network goals-net goals-react



docker run --name goals-backend --rm -d -v "C:\Developer\Docker-Bootcamp\Section 5\multi-01-starting-setup\backend:/app" -v logs:/app/logs -v /app/node_modules -p 80:80 --network goals-net goals-node