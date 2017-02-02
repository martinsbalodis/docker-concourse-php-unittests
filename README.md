# Laravel testing container for concourse.ci
This container was built for concourse.ci. Currently concourse.ci doesn't 
support running additional containers that are needed for test environment. 
So this container contains all in wonder services. Alternatively you could run 
docker in docker. Last time I checked the image weighted 1.5 GB :(


Container has these packages/services installed:

 * php
 * nodejs
 * build-essential
 * selenium
 * firefox
 * chromedriver
 * chromium-browser
 * vnc
 * mysql
 * mongodb

You can access these services:

 * Selenium - port: `4444`
 * Chromedriver - port: `9515`
 * VNC - port: `5901`, password: `selenium`
 * MySQL - port: `3306`, user: `root`, password: `root`, database: `$DB_DATABASE` or `test_database`
 * MongoDB - port: `27017`
 
## Features

`/root/Pictures` contains 10 images from `/root/Pictures/1.jpg` to `/root/Pictures/10.jpg`.
Use these images when testing uploads.

## Build locally:

```bash
docker build --no-cache --tag=martinsbalodis/concourse-php-unittests .
docker push martinsbalodis/concourse-php-unittests
```

## Concourse configuration

Sample concourse task script `build.yml`:

```yml
platform: linux

params:
  GITHUB_OAUTH_TOKEN: ""
  DEFAULT_FILESYSTEM: "local"
  APP_KEY: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  CACHE_DRIVER: "file"
  SESSION_DRIVER: "file"
  QUEUE_DRIVER: "database"

image_resource:
  type: docker-image
  source:
    repository: martinsbalodis/concourse-php-unittests
    tag: latest

inputs:
- name: my_repository.git

run:
  path: ./my_repository.git/ci/test.sh
```


Sample test run script `./my-repo/ci/test.sh`:

```bash
#!/usr/bin/env bash

# print all commands that are executed. fail on any error
set -e -x

# start all dependency services
/run.sh &
sleep 10

# Some debugging
mysql -uroot -p$DB_PASSWORD -e "show databases"
#env
#echo "current working directory - $PWD"
#ls -la
#ls -la *

# change working directory to source root
cd my_repository.git

# authenticate into github to make composer work
/usr/local/bin/composer config -g github-oauth.github.com $GITHUB_OAUTH_TOKEN

# install dependencies
composer install --no-progress --no-suggest
npm install
bower install --allow-root
gulp

# remove node packages that were only for gulp
rm -rf node_modules
rm -rf vendor/bower_components

# migrate database
composer dump-autoload
php artisan migrate --force
php artisan db:seed --force

# run tests
set +e
php vendor/bin/phpunit --configuration phpunit.xml tests
TEST_EXIT_CODE=$?
echo $TEST_EXIT_CODE

# stop all services
/stop.sh

# return unit test exit code
exit $TEST_EXIT_CODE
```

Run unittest from local project on a concourse worker:

```bash
GITHUB_OAUTH_TOKEN="mytoken" fly -t ci execute -x -c build.yml
```

Sample pipeline configuration:

```yml
jobs:
- name: phpunit
  plan:
  - get: my_repository.git
    trigger: true
  - task: unit
    file: my_repository.git/build.yml
    params:
      GITHUB_OAUTH_TOKEN: {{github_oauth_token}}
      DEFAULT_FILESYSTEM: "local"
```