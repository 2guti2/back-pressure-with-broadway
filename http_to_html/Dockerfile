FROM elixir:1.10.4-alpine AS builder

WORKDIR /home/app

RUN mix local.hex --force && mix local.rebar --force

COPY . .

RUN mix deps.update --all

RUN mix deps.get

CMD mix phx.server
