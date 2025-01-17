#!/bin/bash
set -ex

git add -A
git commit -m "enable authn k8s"

export COMPOSE_PROJECT_NAME=clirubydev

docker-compose build

if [ ! -f data_key ]; then
  echo "Generating data key"
  docker-compose pull
  docker-compose run --no-deps --rm conjur data-key generate > data_key
fi

export CONJUR_DATA_KEY="$(cat data_key)"

docker-compose up -d
docker-compose exec conjur conjurctl wait

apikey=$(docker-compose exec conjur \
  conjurctl role retrieve-key cucumber:user:admin)

set +x
echo ''
echo ''
echo '=============== LOGIN WITH THESE CREDENTIALS ==============='
echo ''
echo 'username: admin'
echo "api key : ${apikey}"
echo ''
echo '============================================================'
echo ''
echo ''
set -x



docker-compose exec cli gem install pry
# docker-compose exec cli conjur authn login -u admin -p "$apikey"
docker-compose exec cli bash
