defmodule Sermo.Repo do
  use Ecto.Repo,
    otp_app: :sermo,
    adapter: Ecto.Adapters.Postgres
end
