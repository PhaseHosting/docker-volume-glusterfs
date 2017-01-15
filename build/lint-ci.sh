#!/usr/bin/env bash

if [ -x "$(which travis)" ]; then
	travis lint .travis.yml --skip-version-check
else
	printf "\e[0;31mYou do not have the TravisCI command line installed.\e[0m You should do this:\n"
	if [ ! -x "$(which gem)" ]; then
		printf "\tapt-get install ruby\n"
	fi
	printf "\tgem install travis -N\n"
fi
