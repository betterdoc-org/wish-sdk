defmodule WishSdk.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: WishSdk.Finch}
    ]

    opts = [strategy: :one_for_one, name: WishSdk.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
