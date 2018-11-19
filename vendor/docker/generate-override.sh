#!/bin/sh

OPTS=hi:n:p:k:K:
ARGS=$(getopt $OPTS "$*" 2>/dev/null)

print_usage() {
    printf "Usage: %s [-%s]\\n" "$0" "$OPTS"
    printf "\\n"
    printf "     -h         Print this help.\\n"
    printf "\\n"
    printf "Config:\\n"
    printf "\\n"
    printf "     -i image   Specify an alternative eWallet image name.\\n"
    printf "     -n network Specify an external network.\\n"
    printf "     -p passwd  Specify a PostgreSQL password.\\n"
    printf "     -k key1    Specify an eWallet secret key.\\n"
    printf "     -K key2    Specify a local ledger secret key.\\n"
    printf "\\n"
}

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    print_usage
    exit 1
fi

# shellcheck disable=SC2086
set -- $ARGS

IMAGE_NAME=""
POSTGRES_PASSWORD=""
EXTERNAL_NETWORK=""
EWALLET_SECRET_KEY=""
LOCAL_LEDGER_SECRET_KEY=""

while true; do
    case "$1" in
        -i ) IMAGE_NAME=$2;              shift; shift;;
        -n ) EXTERNAL_NETWORK=$2;        shift; shift;;
        -p ) POSTGRES_PASSWORD=$2;       shift; shift;;
        -k ) EWALLET_SECRET_KEY=$2;      shift; shift;;
        -K ) LOCAL_LEDGER_SECRET_KEY=$2; shift; shift;;
        -h ) print_usage; exit 2;;
        *  ) break;;
    esac
done

[ -z "$IMAGE_NAME" ]              && IMAGE_NAME="omisego/ewallet:dev"
[ -z "$EWALLET_SECRET_KEY" ]      && EWALLET_SECRET_KEY=$(openssl rand -base64 32)
[ -z "$LOCAL_LEDGER_SECRET_KEY" ] && LOCAL_LEDGER_SECRET_KEY=$(openssl rand -base64 32)
[ -z "$POSTGRES_PASSWORD" ]       && POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr '+/' '-_')

cat <<EOF
version: "3"
services:
  postgres:
    environment:
      POSTGRESQL_PASSWORD: $POSTGRES_PASSWORD

  ewallet:
    image: $IMAGE_NAME
    environment:
      DATABASE_URL: postgresql://postgres:$POSTGRES_PASSWORD@postgres:5432/ewallet
      LOCAL_LEDGER_DATABASE_URL: postgresql://postgres:$POSTGRES_PASSWORD@postgres:5432/local_ledger
      EWALLET_SECRET_KEY: $EWALLET_SECRET_KEY
      LOCAL_LEDGER_SECRET_KEY: $LOCAL_LEDGER_SECRET_KEY
EOF

if [ -n "$EXTERNAL_NETWORK" ]; then
    cat <<EOF

networks:
  intnet:
    external:
      name: $EXTERNAL_NETWORK
EOF
fi
