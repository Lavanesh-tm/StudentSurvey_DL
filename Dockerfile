# Use lightweight NGINX image
FROM nginx:latest

# Copy all files from the current directory to the NGINX web root
COPY . /usr/share/nginx/html

# Expose port 80 for web traffic
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]
