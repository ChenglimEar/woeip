#!/bin/bash

DEBUG=true SECRET_KEY=replace-me DATABASE_URL=psql://gitpod:gitpod@localhost:5432/postgres python manage.py runserver
