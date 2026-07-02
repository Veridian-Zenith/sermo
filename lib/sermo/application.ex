defmodule Sermo.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SermoWeb.Telemetry,
      Sermo.Repo,
      {DNSCluster, query: Application.get_env(:sermo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Sermo.PubSub},
      SermoWeb.Presence,
      # Start to serve requests, typically the last entry
      SermoWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sermo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SermoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
