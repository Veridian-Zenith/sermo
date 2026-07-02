import Config

# Log only warnings and errors in production
config :logger, level: :warning

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Runtime production configuration is in config/runtime.exs.
