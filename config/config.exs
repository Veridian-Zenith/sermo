# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :sermo,
  ecto_repos: [Sermo.Repo],
  generators: [timestamp_type: :utc_datetime]

enc_key =
  "sermo-recovery-encryption-key-dev-secret-32bytes!"
  |> then(fn s ->
    if byte_size(s) >= 32 do
      binary_part(s, 0, 32)
    else
      raise "dev recovery encryption key too short"
    end
  end)

config :sermo, :recovery_encryption_key, enc_key

# Configure the endpoint
config :sermo, SermoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: SermoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Sermo.PubSub,
  live_view: [signing_salt: "do9zhUZ8"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :sermo, Sermo.Mailer, adapter: Swoosh.Adapters.Local

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
