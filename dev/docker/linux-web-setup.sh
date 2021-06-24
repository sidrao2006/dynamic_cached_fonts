#!/bin/bash

# Version
CHROME_DRIVER_VERSION=$(curl -sS https://chromedriver.storage.googleapis.com/LATEST_RELEASE)

# Install dependencies.
apt-get install -y unzip openjdk-8-jre-headless xvfb libxi6 libgconf-2-4

# Install Chrome.
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -P ~/
apt-get -y install ~/google-chrome-stable_current_amd64.deb
rm ~/google-chrome-stable_current_amd64.deb

# Install ChromeDriver.
wget -N "https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip" -P ~/
unzip ~/chromedriver_linux64.zip -d ~/
rm ~/chromedriver_linux64.zip
mv -f ~/chromedriver /usr/local/bin/chromedriver
chown root:root /usr/local/bin/chromedriver
chmod 0755 /usr/local/bin/chromedriver
