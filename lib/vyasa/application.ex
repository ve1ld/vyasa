defmodule Vyasa.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      VyasaWeb.Telemetry,
      Vyasa.Repo,
      {DNSCluster, query: Application.get_env(:vyasa, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Vyasa.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch,
       name: Vyasa.Finch,
       pools: %{
         default: [
           conn_opts: [
             transport_opts: [
               cacertfile: "priv/cacerts.pem"
             ]
           ]
         ]
       }},
      # Start a worker by calling: Vyasa.Worker.start_link(arg)
      # {Vyasa.Worker, arg},
      # Start to serve requests, typically the last entry
      VyasaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Vyasa.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VyasaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
