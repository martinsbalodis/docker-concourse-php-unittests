#!/usr/bin/env bash

supervisorctl stop mongodb mysqld selenium tightvnc
supervisorctl shutdown