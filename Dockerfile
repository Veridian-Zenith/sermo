ARG ELIXIR_VERSION=1.20
ARG OTP_VERSION=29
ARG DEBIAN_VERSION=bookworm

FROM hexpm/elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION}-debian-${DEBIAN_VERSION} AS build

ENV MIX_ENV=prod \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends build-essential git ca-certificates && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

# Fetch and compile dependencies first to maximize layer caching.
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV

COPY config config
COPY lib lib
COPY priv priv
COPY rel rel

RUN mix deps.compile && \
    mix compile && \
    mix phx.digest && \
    mix release sermo

# ---- Runtime image -------------------------------------------------------
FROM debian:${DEBIAN_VERSION}-slim AS app

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/app

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends libssl3 ca-certificates && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

COPY --from=build /app/_build/prod/rel/sermo ./

EXPOSE 4000

CMD ["/app/bin/sermo", "start"]
