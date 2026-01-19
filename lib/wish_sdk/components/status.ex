defmodule WishSdk.Components.Status do
  @moduledoc """
  Component for displaying BetterPrompt connection and streaming status.

  ## Examples

      <.wish_status status={:connected} />
      <.wish_status status={:streaming} message="Generating..." />
      <.wish_status status={:error} message="Connection failed" />
  """
  use Phoenix.Component

  attr :status, :atom,
    default: :idle,
    values: [:idle, :connecting, :connected, :streaming, :done, :error],
    doc: "Current status"

  attr :message, :string, default: nil, doc: "Optional status message"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :rest, :global, doc: "Additional HTML attributes"

  def wish_status(assigns) do
    ~H"""
    <div class={["wish-status inline-flex items-center", status_class(@status), @class]} {@rest}>
      <%= if show_spinner?(@status) do %>
        <svg
          class="animate-spin -ml-1 mr-2 h-4 w-4"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
          </circle>
          <path
            class="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          >
          </path>
        </svg>
      <% else %>
        <span class="mr-2 h-2 w-2 rounded-full" class={dot_class(@status)}></span>
      <% end %>
      <span class="text-sm font-medium">
        <%= @message || default_message(@status) %>
      </span>
    </div>
    """
  end

  defp status_class(:idle), do: "text-gray-500"
  defp status_class(:connecting), do: "text-blue-600"
  defp status_class(:connected), do: "text-green-600"
  defp status_class(:streaming), do: "text-blue-600"
  defp status_class(:done), do: "text-green-600"
  defp status_class(:error), do: "text-red-600"

  defp dot_class(:idle), do: "bg-gray-400"
  defp dot_class(:connecting), do: "bg-blue-500 animate-pulse"
  defp dot_class(:connected), do: "bg-green-500"
  defp dot_class(:streaming), do: "bg-blue-500 animate-pulse"
  defp dot_class(:done), do: "bg-green-500"
  defp dot_class(:error), do: "bg-red-500"

  defp show_spinner?(:connecting), do: true
  defp show_spinner?(:streaming), do: true
  defp show_spinner?(_), do: false

  defp default_message(:idle), do: "Ready"
  defp default_message(:connecting), do: "Connecting..."
  defp default_message(:connected), do: "Connected"
  defp default_message(:streaming), do: "Streaming..."
  defp default_message(:done), do: "Complete"
  defp default_message(:error), do: "Error"
end
