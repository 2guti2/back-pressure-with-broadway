# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :http_to_html, HttpToHtmlWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "94fEwcphjKXvjms7yRv0RvXZNi3INRDImWYD2FIyec7P+PMDuqD7NOtuMUsyyXit",
  render_errors: [view: HttpToHtmlWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: HttpToHtml.PubSub,
  live_view: [signing_salt: "lCCBGcC6"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
