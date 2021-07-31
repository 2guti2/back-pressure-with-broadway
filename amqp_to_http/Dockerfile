FROM elixir:1.10.4-alpine AS builder

WORKDIR /apps/api

RUN apt-get update
RUN apt-get install --yes git build-essential inotify-tools
RUN mix local.hex --force && mix local.rebar --force

COPY . .

RUN mix deps.get

CMD mix run --no-halt
