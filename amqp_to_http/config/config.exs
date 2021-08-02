use Mix.Config

config :amqp_to_http,
       amqp_host: System.get_env("AMQP_HOST", "localhost"),
       http_host: System.get_env("HTTP_HOST", "localhost")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
