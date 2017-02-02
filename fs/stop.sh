#!/usr/bin/env bash

supervisorctl stop chromedriver mongodb mysqld selenium tightvnc
supervisorctl shutdown