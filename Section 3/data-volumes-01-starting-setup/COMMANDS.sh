# This build command is used to build the Docker image with the volumes mounted.
docker build -t feedback-node:volumes .

# This run command is used to run the Docker container with the volumes mounted.
docker run -d --rm -p 3000:80 --name feedback-app -v feedback:/app/feedback -v "/Users/lironefitoussi/Developer/Docker-Bootcamp/Section 3/data-volumes-01-starting-setup:/app" -v /app/node_modules feedback-node:volumes

# This run command is used to run the Docker container with the volumes mounted and the read-only flag set.
docker run -d --rm -p 3000:80 --name feedback-app -v feedback:/app/feedback -v "/Users/lironefitoussi/Developer/Docker-Bootcamp/Section 3/data-volumes-01-starting-setup:/app:ro" -v /app/temp -v /app/node_modules feedback-node:volumes

docker run -d --rm -p 3000:80 --name feedback-app \
  -v feedback:/app/feedback \
  -v "/Users/lironefitoussi/Developer/Docker-Bootcamp/Section 3/data-volumes-01-starting-setup:/app" \
  -v /app/node_modules \
  feedback-node:volumes

docker run -d --rm -p 3000:80 -e PORT=8000 --name feedback-app   -v feedback:/app/feedback   -v "/Users/lironefitoussi/Developer/Docker-Bootcamp/Section 3/data-volumes-01-starting-setup:/app"   -v /app/node_modules   feedback-node:env

docker run -d --rm -p 3000:80 -env-file .env --name feedback-app   -v feedback:/app/feedback   -v "/Users/lironefitoussi/Developer/Docker-Bootcamp/Section 3/data-volumes-01-starting-setup:/app"   -v /app/node_modules   feedback-node:env