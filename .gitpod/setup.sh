#!/bin/bash

make requirements
pipenv run make migrate
pipenv run python ./manage.py createsuperuser
pipenv shell
