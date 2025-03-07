defmodule Vyasa.MixProject do
  use Mix.Project

  def project do
    [
      app: :vyasa,
      version: "0.1.0-alpha.1",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [
        warnings_as_errors: true
      ],
      escript: escript(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Vyasa.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Defining Scripting Env
  defp escript do
    [main_module: VyasaCLI]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.0.4" },
      {:floki, ">= 0.30.0"},
      {:phoenix_live_dashboard, "~> 0.8.6"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.1.1"},
      {:plug_cowboy, "~> 2.5"},
      {:ecto_ltree, "~> 0.4.0"},
      {:image, "~> 0.53"},
      {:vix, "~> 0.5"},
      {:kino, "~> 0.13"},
      {:cors_plug, "~> 3.0"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.5"},
      {:live_admin, live_admin_dep()},
      {:req, "~> 0.4.0"},
      {:recase, "~> 0.5"},
      {:timex, "~> 3.0"},
      {:ua_parser, "~> 1.9"},
      {:inflex, "~> 2.1"},
      {:youtube_captions, "~> 0.1.0", runtime: Mix.env() == :dev}

    ]
  end

  defp live_admin_dep() do
    if path = System.get_env("LA_PATH") do
      [path: path]
    else
      [github: "ks0m1c/live_admin", ref: "8201e03"]
    end
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify --loader:.ttf=file",
        "phx.digest"
      ]
    ]
  end
end
