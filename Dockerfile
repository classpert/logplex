FROM voidlock/erlang:18.1.3 AS build

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
ADD . /usr/src/app
VOLUME /root/.cache
RUN curl --silent -L --fail --max-time 10 -o /usr/local/bin/rebar3 https://github.com/erlang/rebar3/releases/download/3.5.0/rebar3 && chmod +x /usr/local/bin/rebar3
RUN REBAR=/usr/local/bin/rebar3 make compile

FROM voidlock/erlang:18.1.3

ENV ERL_CRASH_DUMP=/dev/null

EXPOSE 8001 8601 6001 4369 49000

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY --from=build /usr/src/app /usr/src/app

CMD ["./_build/default/rel/logplex/bin/logplex", "foreground"]
