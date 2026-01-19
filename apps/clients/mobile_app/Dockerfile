# ==============================================================================
# DOCKERFILE: FLUTTER FRONTEND (PRODUCTION)
# Context: Requires 'flutter build web' artifact from the workflow.
# ==============================================================================

FROM nginx:alpine

# 1. Clean Default Config
# Remove default Nginx welcome page
RUN rm -rf /usr/share/nginx/html/*

# 2. Configuration
# Copy custom Nginx config to support SPA routing (Flutter)
# IMPORTANT: This file must exist in your repo at this path!
COPY apps/clients/mobile_app/nginx.conf /etc/nginx/conf.d/default.conf

# 3. Static Assets
# Copy the compiled Flutter web files from the build context
COPY apps/clients/mobile_app/build/web /usr/share/nginx/html

# 4. Runtime
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]