defmodule WishSdk.Components do
  @moduledoc """
  All WishSdk LiveView components.

  To use these components, add to your web module:

      use WishSdk.Components

  This will import all available components.

  ## Available Components

  - `wish_response` - Display responses with status, streaming, and error handling
  - `wish_status` - Show connection status indicators
  - `WishSdk.Components.LivePrompt` - Self-managing LiveComponent (use via `live_component`)
  """

  defmacro __using__(_) do
    quote do
      import WishSdk.Components.{
        Response,
        Status
      }

      # LivePrompt is a LiveComponent, so it's used via live_component/1
      alias WishSdk.Components.LivePrompt
    end
  end
end
