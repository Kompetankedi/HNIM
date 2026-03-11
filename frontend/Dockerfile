# Stage 1: Build Flutter Web
FROM ubuntu:22.04 AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Pre-download Flutter artifacts
RUN flutter doctor

WORKDIR /app
COPY . .

# Build for web
RUN flutter pub get
RUN flutter build web --release --base-href /

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
