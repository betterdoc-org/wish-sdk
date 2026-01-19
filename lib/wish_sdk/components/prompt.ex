defmodule WishSdk.Components.Prompt do
  @moduledoc """
  LiveView component for interactive BetterPrompt integration with streaming support.

  ## Examples

      <.wish_prompt
        slug="medical-summary"
        context_variables={%{case_id: @case_id}}
        user_prompt={@user_prompt}
        streaming={true}
      />

      # With event handlers
      <.wish_prompt
        slug="medical-summary"
        context_variables={%{case_id: @case_id}}
        phx-chunk="handle_chunk"
        phx-done="handle_done"
        phx-error="handle_error"
      />
  """
  use Phoenix.Component
  import WishSdk.Components.Status
  import WishSdk.Components.Response

  attr :response, :string, default: "", doc: "Current response content"

  attr :status, :atom,
    default: :idle,
    values: [:idle, :connecting, :streaming, :done, :error],
    doc: "Current status"

  attr :format, :string, default: "markdown", doc: "Response format: markdown, text, html"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :show_status, :boolean, default: true, doc: "Show status indicator"
  attr :auto_scroll, :boolean, default: false, doc: "Auto-scroll response during streaming"

  attr :rest, :global, doc: "Additional HTML attributes"

  @doc """
  Displays a BetterPrompt response with optional status.

  This is a pure display component - all logic is handled server-side in your LiveView.
  By default, renders responses as markdown.

  ## Example

      # In your LiveView
      def mount(_params, _session, socket) do
        {:ok, assign(socket, response: "", status: :idle)}
      end

      def handle_event("invoke", _params, socket) do
        socket = assign(socket, status: :streaming)

        {:ok, _task} = WishSdk.stream("my-prompt",
          context_variables: %{id: "123"},
          on_chunk: fn chunk -> send(self(), {:chunk, chunk}) end,
          on_done: fn response -> send(self(), {:done, response}) end
        )

        {:noreply, socket}
      end

      def handle_info({:chunk, chunk}, socket) do
        {:noreply, update(socket, :response, &(&1 <> chunk))}
      end

      def handle_info({:done, _}, socket) do
        {:noreply, assign(socket, status: :done)}
      end

      # In your template (markdown is default)
      <.wish_prompt response={@response} status={@status} />

      # Or specify format explicitly
      <.wish_prompt response={@response} status={@status} format="text" />
  """
  def wish_prompt(assigns) do
    ~H"""
    <div class={["wish-prompt", @class]} {@rest}>
      <%= if @show_status do %>
        <div class="mb-3">
          <.wish_status status={@status} />
        </div>
      <% end %>

      <.wish_response
        content={@response}
        format={@format}
        streaming={@status == :streaming}
        auto_scroll={@auto_scroll}
      />
    </div>
    """
  end
end
