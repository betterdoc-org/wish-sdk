defmodule WishSdk.Components.Response do
  @moduledoc """
  Component for displaying formatted BetterPrompt responses.

  ## Examples

      # Markdown (default)
      <.wish_response content={@response} />

      # With streaming cursor and auto-scroll
      <.wish_response content={@response} streaming={true} auto_scroll={true} />

      # Plain text
      <.wish_response content={@response} format="text" />

      # Loading state with size
      <.wish_response content="" loading={true} size="small" />
      <.wish_response content="" loading={true} size="medium" />
      <.wish_response content="" loading={true} size="large" />
  """
  use Phoenix.Component

  attr :content, :string, required: true, doc: "Response content to display"
  attr :format, :string, default: "markdown", doc: "Content format: text, markdown, html"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :loading, :boolean, default: false, doc: "Show loading spinner"
  attr :streaming, :boolean, default: false, doc: "Show streaming cursor (markdown only)"
  attr :size, :string, default: "medium", doc: "Spinner size: small, medium, large"
  attr :auto_scroll, :boolean, default: false, doc: "Auto-scroll to bottom during updates"
  attr :rest, :global, doc: "Additional HTML attributes"

  def wish_response(assigns) do
    ~H"""
    <div class={["wish-response", @class]} {@rest}>
      <%= if @loading do %>
        <%= case @size do %>
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
      <% else %>
        <div
          class="wish-response-content"
          id={if @auto_scroll, do: "wish-response-#{System.unique_integer([:positive])}", else: nil}
          phx-hook={if @auto_scroll, do: "WishResponseAutoScroll", else: nil}
          data-auto-scroll={if @auto_scroll, do: "true", else: "false"}
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
        </div>
      <% end %>
    </div>
    """
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
