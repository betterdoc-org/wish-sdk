defmodule WishSdk.Components.Response do
  @moduledoc """
  The one component to rule them all - handles response display with automatic state management.

  ## Examples

      # Using status atom (recommended - simplest API)
      <.wish_response
        content={@response}
        status={@status}
        show_status={true}
        class="bg-white border rounded-lg p-6 min-h-[200px]"
      />

      # Or use individual flags (more control)
      <.wish_response
        content={@response}
        loading={@streaming and @response == ""}
        error={@error}
        streaming={@streaming}
      />

      # With custom empty message
      <.wish_response
        content={@response}
        status={@status}
        empty_message="Click 'Start Streaming' to begin"
      />

      # Disable auto-scroll
      <.wish_response content={@response} auto_scroll={false} />

      # Custom scroll container height
      <.wish_response
        content={@response}
        container_class="max-h-[500px] overflow-y-auto"
      />

      # Plain text format
      <.wish_response content={@response} format="text" />

  ## Status Atom vs Individual Flags

  You can control state in two ways:

  ### Option 1: Status Atom (Simpler)
  Pass a single `:status` atom and the component derives everything:
  - `:idle` → Empty state
  - `:connecting` → Loading spinner (if no content yet)
  - `:streaming` → Streaming cursor + loading (if no content)
  - `:done` → Just content, no cursor
  - `:error` → Error display

  ### Option 2: Individual Flags (More Control)
  Set `:loading`, `:streaming`, `:error` independently for fine-grained control.

  ## State Priority

  The component handles states in this order:
  1. Error (if `error` is set, shows error message)
  2. Loading (if `loading={true}`, shows spinner)
  3. Empty (if `content=""`, shows empty message)
  4. Content (shows the actual response with optional streaming cursor)

  ## Auto-scroll behavior

  When `auto_scroll={true}` (default):
  - The component automatically adds `overflow-y-auto` and `max-h-96` classes
  - Works with the optional `WishResponseAutoScroll` JavaScript hook
  - Scrolling stops automatically when user manually scrolls (wheel event)
  - You can customize the container height with the `container_class` attribute
  """
  use Phoenix.Component
  import WishSdk.Components.Status

  attr :content, :string, default: "", doc: "Response content to display"
  attr :format, :string, default: "markdown", doc: "Content format: text, markdown, html"
  attr :class, :string, default: "", doc: "Additional CSS classes"

  # State attributes
  attr :status, :atom,
    default: nil,
    values: [nil, :idle, :connecting, :connected, :streaming, :done, :error],
    doc: "Status atom (alternative to individual loading/streaming/error flags)"

  attr :loading, :boolean,
    default: false,
    doc: "Show loading spinner (overridden by status if set)"

  attr :streaming, :boolean,
    default: true,
    doc: "Show streaming cursor (overridden by status if set)"

  attr :error, :any,
    default: nil,
    doc: "Error message to display (string or map with :status and :message keys)"

  # Display options
  attr :show_status, :boolean, default: false, doc: "Show status indicator above response"

  attr :loading_size, :string,
    default: "medium",
    doc: "Loading spinner size: small, medium, large"

  attr :empty_message, :string,
    default: "No content yet",
    doc: "Message to show when content is empty and not loading"

  # Scroll options
  attr :auto_scroll, :boolean,
    default: true,
    doc: "Auto-scroll to bottom during updates (requires overflow container)"

  attr :container_class, :string,
    default: "max-h-96 overflow-y-auto",
    doc: "Container classes when auto_scroll is enabled"

  attr :rest, :global, doc: "Additional HTML attributes"

  def wish_response(assigns) do
    # Normalize status atom to individual flags
    assigns =
      assigns
      |> normalize_status_flags()
      |> assign(:container_classes, build_container_classes(assigns))

    ~H"""
    <div>
      <%= if @show_status and @status do %>
        <div class="mb-3">
          <.wish_status status={@status} />
        </div>
      <% end %>

      <div class={@container_classes} {@rest}>
        <%= cond do %>
        <% @error -> %>
          <div class="wish-response-error bg-red-50 border border-red-200 rounded-lg p-4">
            <h3 class="text-red-900 font-semibold mb-2">Error</h3>
            <pre class="text-sm text-red-800 whitespace-pre-wrap"><%= @error %></pre>
          </div>

        <% @loading -> %>
          <%= case @loading_size do %>
          <% "small" -> %>
            <div class="wish-response-loading inline-flex items-center space-x-2 text-gray-500 p-4">
              <svg
                class="animate-spin w-4 h-4 flex-shrink-0"
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
              <span class="text-xs">Generating response...</span>
            </div>
          <% "large" -> %>
            <div class="wish-response-loading inline-flex items-center space-x-2 text-gray-500 p-4">
              <svg
                class="animate-spin w-8 h-8 flex-shrink-0"
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
              <span class="text-base">Generating response...</span>
            </div>
          <% _ -> %>
            <div class="wish-response-loading inline-flex items-center space-x-2 text-gray-500 p-4">
              <svg
                class="animate-spin w-5 h-5 flex-shrink-0"
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
              <span class="text-sm">Generating response...</span>
            </div>
          <% end %>

        <% @content == "" -> %>
          <div class="wish-response-empty text-center text-gray-500 p-6">
            <%= @empty_message %>
          </div>

        <% true -> %>
          <div
            class="wish-response-content"
            id={if @auto_scroll, do: "wish-response-#{System.unique_integer([:positive])}", else: nil}
            phx-hook={if @auto_scroll, do: "WishResponseAutoScroll", else: nil}
            data-auto-scroll={if @auto_scroll, do: "true", else: "false"}
            data-streaming={if @auto_scroll, do: to_string(@streaming), else: nil}
          >
            <%= case @format do %>
              <% "markdown" -> %>
                <div class="prose prose-sm max-w-none">
                  <%= Phoenix.HTML.raw(format_markdown(@content)) %>
                  <%= if @streaming do %>
                    <span class="inline-block w-2 h-4 bg-blue-600 animate-pulse ml-1"></span>
                  <% end %>
                </div>
              <% "html" -> %>
                <%= Phoenix.HTML.raw(@content) %>
              <% _ -> %>
                <div class="whitespace-pre-wrap"><%= @content %></div>
            <% end %>
            <span data-wish-response-end class="sr-only"></span>
          </div>
      <% end %>
      </div>
    </div>
    """
  end

  defp normalize_status_flags(assigns) do
    # If status atom is provided, derive loading/streaming/error from it
    # Otherwise, use the individual flags
    case Map.get(assigns, :status) do
      nil ->
        # No status atom, use individual flags as-is
        assigns
        |> Map.update(:error, nil, &format_error/1)

      :error ->
        # Error state - if no error message, use default
        error_msg = Map.get(assigns, :error) || "An error occurred"

        assigns
        |> Map.put(:error, format_error(error_msg))
        |> Map.put(:loading, false)
        |> Map.put(:streaming, false)

      status when status in [:connecting, :connected, :streaming] ->
        # Streaming/connecting/connected - show as loading if no content yet
        content = Map.get(assigns, :content, "")

        assigns
        |> Map.put(:loading, content == "")
        |> Map.put(:streaming, true)
        |> Map.put(:error, nil)

      :done ->
        # Done - show content without streaming cursor
        assigns
        |> Map.put(:loading, false)
        |> Map.put(:streaming, false)
        |> Map.put(:error, nil)

      :idle ->
        # Idle - not loading, not streaming
        assigns
        |> Map.put(:loading, false)
        |> Map.put(:streaming, false)
        |> Map.put(:error, nil)
    end
  end

  defp format_error(nil), do: nil

  defp format_error(error) when is_binary(error), do: error

  defp format_error(%{status: status, message: message}) when is_integer(status) do
    "HTTP #{status}: #{message}"
  end

  defp format_error(%{message: message}) when is_binary(message) do
    message
  end

  defp format_error(error) do
    inspect(error)
  end

  defp build_container_classes(assigns) do
    base_classes = ["wish-response"]

    # Add overflow container classes when auto_scroll is enabled
    # Don't add overflow classes when loading (loading state shouldn't scroll)
    auto_scroll = Map.get(assigns, :auto_scroll, true)
    loading = Map.get(assigns, :loading, false)

    overflow_classes =
      if auto_scroll and not loading do
        container_class = Map.get(assigns, :container_class, "max-h-96 overflow-y-auto")
        String.split(container_class, " ", trim: true)
      else
        []
      end

    # Add user's custom classes
    custom_classes =
      case Map.get(assigns, :class, "") do
        "" -> []
        class_str -> String.split(class_str, " ", trim: true)
      end

    base_classes ++ overflow_classes ++ custom_classes
  end

  defp format_markdown(content) do
    case Earmark.as_html(content,
           code_class_prefix: "lang- language-",
           gfm: true,
           pure_links: true
         ) do
      {:error, html, _} -> html
      {:ok, html, _} -> html
    end
  end
end
