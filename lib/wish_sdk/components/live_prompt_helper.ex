defmodule WishSdk.Components.LivePromptHelper do
  @moduledoc """
  Helper for LiveViews that use LivePrompt components.

  Add this to your LiveView to enable LivePrompt components to work:

      defmodule MyAppWeb.MyLive do
        use MyAppWeb, :live_view
        use WishSdk.Components.LivePromptHelper  # <- Add this line

        def render(assigns) do
          ~H\"\"\"
          <.live_component
            module={WishSdk.Components.LivePrompt}
            id="my-prompt"
            slug="medical-summary"
            context_variables={%{case_id: @case_id}}
            auto_start={true}
          />
          \"\"\"
        end
      end

  That's it! The helper automatically handles all internal messages.

  ## With Custom handle_info

  If you have your own handle_info clauses, make sure to call the helper's
  handler for unmatched messages:

      def handle_info({:my_custom_message, data}, socket) do
        # Your custom logic
        {:noreply, socket}
      end

      def handle_info(msg, socket) do
        # Delegate to helper
        WishSdk.Components.LivePromptHelper.handle_live_prompt_message(msg, socket)
      end
  """

  defmacro __using__(_opts) do
    quote do
      import WishSdk.Components.LivePromptHelper, only: [handle_live_prompt_message: 2]
    end
  end

  @doc """
  Handles LivePrompt internal messages. Call this from your handle_info catch-all.
  """
  def handle_live_prompt_message({:live_prompt_connected, component_id}, socket) do
    Phoenix.LiveView.send_update(WishSdk.Components.LivePrompt,
      id: component_id,
      pubsub_action: :connected
    )
    {:noreply, socket}
  end

  def handle_live_prompt_message({:live_prompt_chunk, component_id, chunk}, socket) do
    Phoenix.LiveView.send_update(WishSdk.Components.LivePrompt,
      id: component_id,
      pubsub_action: :chunk,
      chunk: chunk
    )
    {:noreply, socket}
  end

  def handle_live_prompt_message({:live_prompt_done, component_id, response}, socket) do
    Phoenix.LiveView.send_update(WishSdk.Components.LivePrompt,
      id: component_id,
      pubsub_action: :done,
      response: response
    )
    {:noreply, socket}
  end

  def handle_live_prompt_message({:live_prompt_error, component_id, error}, socket) do
    Phoenix.LiveView.send_update(WishSdk.Components.LivePrompt,
      id: component_id,
      pubsub_action: :error,
      error: error
    )
    {:noreply, socket}
  end

  def handle_live_prompt_message(_msg, socket) do
    {:noreply, socket}
  end
end
