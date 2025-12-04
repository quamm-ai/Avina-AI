#!/bin/sh
# This script runs before nginx starts, inside the container.

# Define the source and destination for the landing page
TEMPLATE_FILE="/var/www/static_html/index.html.template"
OUTPUT_FILE="/var/www/static_html/index.html"

# Substitute environment variables into the template file
# and create the final index.html.
# The `envsubst` command is available in the base nginx image.
envsubst '${DOMAIN} ${ENV_TYPE}' < "$TEMPLATE_FILE" > "$OUTPUT_FILE"

# The original entrypoint script will continue and start nginx.
exit 0
