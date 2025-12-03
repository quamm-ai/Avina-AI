# /nginx/Dockerfile
# Use a specific, stable version of NGINX instead of :latest
FROM nginx:1.25-alpine

# When NGINX starts, it will substitute the environment variables in the template
# and write the final config to the correct location.
COPY nginx.conf /etc/nginx/templates/nginx.conf.template

# Set the entrypoint to automatically handle environment variable substitution.
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
