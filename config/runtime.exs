import Config

if System.get_env("PHX_SERVER") do
  config :sermo, SermoWeb.Endpoint, server: true
end

config :sermo, SermoWeb.Endpoint, http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :sermo, Sermo.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "2"),
    socket_options: maybe_ipv6

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  recovery_key =
    System.get_env("RECOVERY_ENCRYPTION_KEY") ||
      raise """
      environment variable RECOVERY_ENCRYPTION_KEY is missing.
      Generate a 32-byte key with: mix run -e 'IO.puts(:crypto.strong_rand_bytes(32) |> Base.encode64())'
      """

  recovery_key_bytes =
    recovery_key
    |> Base.decode64!()
    |> then(fn k ->
      if byte_size(k) == 32,
        do: k,
        else: raise("RECOVERY_ENCRYPTION_KEY must decode to exactly 32 bytes")
    end)

  config :sermo, :recovery_encryption_key, recovery_key_bytes

  config :sermo, SermoWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base
end
