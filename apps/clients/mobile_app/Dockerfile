# ==============================================================================
# DOCKERFILE: FLUTTER FRONTEND (PRODUCTION)
# Context: Serves compiled static files via Nginx.
# Strategy: "Build-Host, Run-Container". 
# (We assume 'flutter build web' is executed on the host machine first).
# ==============================================================================

# 1. Base Image: Nginx Alpine (Lightweight web server)
FROM nginx:alpine

# 2. Housekeeping: Remove default Nginx welcome page
RUN rm -rf /usr/share/nginx/html/*

# 3. Configuration: Copy custom Nginx config for SPA routing support
COPY apps/clients/mobile_app/nginx.conf /etc/nginx/conf.d/default.conf

# 4. Artifacts: Copy the compiled web assets from the host
# NOTE: This path assumes you run 'docker build' from the WORKSPACE ROOT.
# If 'flutter build web' was successful, the files are in build/web.
COPY apps/clients/mobile_app/build/web /usr/share/nginx/html

# 5. Network: Expose standard HTTP port
EXPOSE 80

# 6. Runtime: Start Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]