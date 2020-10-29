#!/bin/bash -e

if [[ -d tt-rss ]]; then
    echo "tt-rss is already installed, skipping."
    exit
fi

: "${TTRSS_GIT_URL:="https://git.tt-rss.org/fox/tt-rss.git"}"
: "${TTRSS_GIT_BRANCH:="master"}"

echo "Downloading tt-rss..."
git clone --branch "$TTRSS_GIT_BRANCH" --depth 1 --recurse-submodules "$TTRSS_GIT_URL" tt-rss

echo "Install Feedly Theme"
wget https://github.com/levito/tt-rss-feedly-theme/archive/master.zip
unzip master.zip
cd tt-rss-feedly-theme-master
cp -r feedly* ../tt-rss/themes.local

echo "Injecting configuration file..."
cp ttrss-config.php tt-rss/config.php

echo "Fixing permissions..."
chmod -R -w tt-rss
chmod +w tt-rss/plugins.local
chmod -R 777 tt-rss/cache tt-rss/lock tt-rss/feed-icons

echo "Checking database..."
if ! psql "$DATABASE_URL" -c 'SELECT schema_version FROM ttrss_version' &>/dev/null; then
    echo "Initializing database..."
    psql "$DATABASE_URL" < tt-rss/schema/ttrss_schema_pgsql.sql >/dev/null
fi

php plugins-installer.php
