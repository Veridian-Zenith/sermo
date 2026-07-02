defmodule Sermo.MixProject do
  use Mix.Project

  def project do
    [
      app: :sermo,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      listeners: [Phoenix.CodeReloader],
      aliases: aliases(),
      deps: deps(),
      releases: [
        sermo: [
          include_executables_for: [:unix],
          steps: [:assemble, &install_bin_script/1]
        ]
      ]
    ]
  end

  def application do
    [
      mod: {Sermo.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test, release: :prod]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.8.8"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:bcrypt_elixir, "~> 3.0"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"],
      release: [
        "deps.compile --quiet",
        &compile_app/1,
        "release sermo --no-compile --quiet"
      ]
    ]
  end

  defp compile_app(_) do
    Logger.configure(level: :error)
    Mix.Task.run("compile", ["--warnings-as-errors"])
    Logger.configure(level: :warning)
  end

  defp install_bin_script(release) do
    Mix.shell().info("Writing bin/server wrapper…")
    File.mkdir_p!(release.path)

    File.write!(Path.join(release.path, "bin/server"), """
    #!/bin/sh
    export PHX_SERVER=true
    export PORT="${PORT:-4000}"
    exec "$(dirname "$0")/sermo" start
    """)

    File.chmod!(Path.join(release.path, "bin/server"), 0o755)
    release
  end
end
