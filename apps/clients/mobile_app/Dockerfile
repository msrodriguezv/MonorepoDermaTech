# ==============================================================================
# DOCKERFILE - FLUTTER WEB CLIENT
# Purpose: Builds the Flutter application for Web and serves it via Nginx.
# ==============================================================================

# ------------------------------------------------------------------------------
# STAGE 1: FLUTTER BUILDER
# Description: Compiles Dart code into HTML/CSS/JS assets.
# ------------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy dependency definitions first
COPY pubspec.* ./

# Resolve Flutter dependencies
RUN flutter pub get

# Copy the rest of the Flutter source code
COPY . .

# Build the application for web release
# --no-tree-shake-icons: Prevents icon font issues in some docker environments
RUN flutter build web --release --no-tree-shake-icons

# ------------------------------------------------------------------------------
# STAGE 2: NGINX SERVER
# Description: Serves static files using a lightweight HTTP server.
# ------------------------------------------------------------------------------
FROM nginx:alpine

# Copy the build output from the builder stage to Nginx's html directory
# Default Flutter web build output is usually in build/web
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose port 80 for HTTP traffic
EXPOSE 80

# Start Nginx in foreground mode
CMD ["nginx", "-g", "daemon off;"]