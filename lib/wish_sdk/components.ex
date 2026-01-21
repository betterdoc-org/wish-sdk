defmodule WishSdk.Components do
  @moduledoc """
  All WishSdk LiveView components.

  To use these components, add to your web module:

      use WishSdk.Components

  This will import all available components.
  """

  defmacro __using__(_) do
    quote do
      import WishSdk.Components.{
        Response,
        Status
      }
    end
  end
end
