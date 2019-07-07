#!/bin/bash

make requirements
pipenv run python -m django --version
pipenv run make migrate
pipenv run python ./manage.py createsuperuser
pipenv run make test
pipenv shell
