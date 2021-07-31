use Mix.Config

config :mqtt_to_amqp, amqp_host: System.get_env("AMQP_HOST", "localhost")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
