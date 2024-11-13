#!/bin/bash

name=$(cat /tmp/user_name)

apps_path="/tmpapps.csv"
curl https://raw.githubusercontent.com/ForgottenScream\arch_installer/master/apps.csv > $apps_path
