#!/bin/bash
function finish {
    echo "Detected SIGTERM, Gracefully Shutting Down..."
    sleep 2
    if kill -s 0 $parent >/dev/null 2>&1; then
        echo "Forwarding SIGTERM to Sub Shell PID: $child..."
        (sleep 0.5; kill -TERM $child >/dev/null 2>&1) &
        wait $parent
        exit_code=$?
        echo "Nginx exited with Exit Code: $exit_code"
        exit $exit_code
    else
        echo "Parent pid not running, usually because of it capturing signals itself.  As a result exit code will be set to 143."
        exit 143
    fi
}
trap finish TERM INT

echo Generating self signed certificate in case letsencrypt fails
mkdir -p /etc/letsencrypt/live/gateway.thoughtdata.thoughtworks.net
cd /etc/letsencrypt/live/gateway.thoughtdata.thoughtworks.net
openssl req \
  -new \
  -newkey rsa:4096 \
  -days 365 \
  -nodes \
  -x509 \
  -subj "/C=UK/ST=Manchester/L=UK/O=ThoughtWorks/CN=gateway.thoughtdata.thoughtworks.net" \
  -keyout key.pem \
  -out fullchain.pem

echo Starting Nginx...
/usr/sbin/nginx -c /etc/nginx/nginx.conf & 
parent=$!
sleep 2
echo Nginx started with pid $parent

if [ "$LETSENCRYPT" == "true" ]; then
  echo Generating LetsEncrypt...
  cd /etc/letsencrypt/live/gateway.thoughtdata.thoughtworks.net
  simp_le --email peopledata-product-team@thoughtworks.com -f account_key.json -f fullchain.pem -f key.pem -d gateway.thoughtdata.thoughtworks.net -d gateway.integration.thoughtdata.thoughtworks.net --default_root /usr/share/nginx/html --tos_sha256 6373439b9f29d67a5cd4d18cbc7f264809342dbf21cb2ba2fc7588df987a6221 
fi

echo Reloading nginx...
nginx -s reload
sleep 2

wait $parent
