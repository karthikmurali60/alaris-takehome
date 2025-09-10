# Application code setup

- The application is written in typeScript using the Express framework. It connects to a PostgreSQL database and exposes endpoints according to the requirements.
- The Dockerfile in the `app/` directory builds the application image. It uses `bun` as the runtime.
- The image is built and pushed to Docker Hub using the `scripts/build-and-push.sh` script. This script is also automated in the `Build and Push Docker Image` GitHub Actions workflow.