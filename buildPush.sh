#!/bin/bash

echo "Construyendo y pusheando imagen..."

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t navidocky/ticketflow_db:latest \
  --push .

echo "Done."
