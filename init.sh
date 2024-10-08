#!/bin/bash

domains=(james-hamilton.uk jameshamiltondata.com jameshamiltonenergy.com)
cert_name=jameshamilton
rsa_key_size=4096
certbot_path="/etc/letsencrypt/live/$cert_name"
host_path="./certbot/conf/live/$cert_name"
email="" # Adding a valid address is strongly recommended

if [ -d "$host_path" ]; then
  read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

# if [ ! -e "$path/options-ssl-nginx.conf" ] || [ ! -e "$path/ssl-dhparams.pem" ]; then
#   echo "### Downloading recommended TLS parameters ..."
#   mkdir -p "$path"
#   curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/options-ssl-nginx.conf"
#   curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$path/ssl-dhparams.pem"
#   echo
# fi

echo "### Creating dummy certificate for $domains ..."
sudo mkdir -p "$host_path"
docker compose run --rm --entrypoint "openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1 -keyout '$certbot_path/privkey.pem' -out '$certbot_path/fullchain.pem' -subj '/CN=localhost'" certbot
echo

echo "### Starting nginx ..."
docker compose up --force-recreate -d nginx
echo

echo "### Deleting dummy certificate for $domains ..."
docker compose run --rm --entrypoint "rm -Rf $certbot_path && rm -Rf /etc/letsencrypt/archive/$cert_name && rm -Rf /etc/letsencrypt/renewal/$cert_name.conf" certbot
echo

echo "### Requesting Let's Encrypt certificate for $domains ..."
# Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done
echo

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

docker compose run --rm --entrypoint "certbot certonly --webroot -w /var/www/certbot $email_arg $domain_args --cert-name $cert_name --rsa-key-size $rsa_key_size --agree-tos --no-eff-email --force-renewal" certbot

echo "### Reloading nginx ..."
docker compose exec nginx nginx -s reload