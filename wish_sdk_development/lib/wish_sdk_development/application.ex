defmodule WishSdkDevelopment.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WishSdkDevelopmentWeb.Telemetry,
      {Phoenix.PubSub, name: WishSdkDevelopment.PubSub},
      WishSdkDevelopmentWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: WishSdkDevelopment.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    WishSdkDevelopmentWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
