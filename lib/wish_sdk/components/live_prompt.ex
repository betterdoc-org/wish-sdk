defmodule WishSdk.Components.LivePrompt do
  @moduledoc """
  A self-managing LiveComponent for WishSdk prompts.

  Handles all streaming/invoke state internally with zero boilerplate required.
  Perfect for simple use cases where you just want to display an AI response
  without managing callbacks and state yourself.

  ## Features

  - ✅ **Zero Boilerplate** - No manual message handling needed
  - ✅ **Self-Managing** - Component handles its own state and lifecycle
  - ✅ **Flexible** - Supports both streaming and invoke modes
  - ✅ **Reusable** - Multiple prompts on one page easily
  - ✅ **Optional Callbacks** - Hook into completion/error events when needed

  ## Basic Examples

      # Simplest possible usage - auto-start streaming
      <.live_component
        module={WishSdk.Components.LivePrompt}
        id="my-prompt"
        slug="medical-summary"
        context_variables={%{case_id: @case_id}}
        auto_start={true}
      />

      # With user control
      <button phx-click={JS.push("start", target: "#my-prompt")}>
        Generate
      </button>

      <.live_component
        module={WishSdk.Components.LivePrompt}
        id="my-prompt"
        slug="medical-summary"
        context_variables={%{case_id: @case_id}}
      />

      # With completion callback
      <.live_component
        module={WishSdk.Components.LivePrompt}
        id="my-prompt"
        slug="medical-summary"
        context_variables={%{case_id: @case_id}}
        auto_start={true}
        on_complete={fn response ->
          send(self(), {:ai_complete, response})
        end}
      />

  ## Attributes

    * `:id` (required) - Unique component ID
    * `:slug` - Prompt slug (either this or `:prompt` required)
    * `:prompt` - Generated prompt struct (either this or `:slug` required)
    * `:context_variables` - Map of context variables (optional if using `:prompt`)
    * `:user_prompt` - User prompt text (optional)
    * `:mode` - `:stream` (default) or `:invoke`
    * `:auto_start` - Start immediately on mount (default: false)
    * `:show_status` - Show status indicator (default: true)
    * `:format` - Content format: "text", "markdown" (default), "html"
    * `:class` - Additional CSS classes for the container
    * `:empty_message` - Message when no content (default: "Click start to generate")
    * `:on_complete` - Callback function when done: `fn response -> ... end`
    * `:on_error` - Callback function on error: `fn error -> ... end`

  ## Programmatic Control

  You can control the component from your LiveView:

      # Start generation
      send_update(WishSdk.Components.LivePrompt,
        id: "my-prompt",
        action: :start
      )

      # Cancel ongoing generation
      send_update(WishSdk.Components.LivePrompt,
        id: "my-prompt",
        action: :cancel
      )

      # Reset to initial state
      send_update(WishSdk.Components.LivePrompt,
        id: "my-prompt",
        action: :reset
      )

  ## Using with Generated Structs

      alias MyApp.Prompts.MedicalSummary

      <.live_component
        module={WishSdk.Components.LivePrompt}
        id="my-prompt"
        prompt={%MedicalSummary{case_id: @case_id, document_id: @doc_id}}
        auto_start={true}
      />

  ## Low-Level Alternative

  If you need more control over message handling or want to coordinate
  multiple prompts, use the low-level `WishSdk.stream/2` or `WishSdk.invoke/2`
  APIs directly with manual message handling.
  """

  use Phoenix.LiveComponent
  require Logger

  # Make this a stateful component so it can receive send_update calls
  @impl true
  def mount(socket) do
    Logger.debug("LivePrompt mount called")
    {:ok,
     socket
     |> assign(:response, "")
     |> assign(:status, :idle)
     |> assign(:error, nil)
     |> assign(:task, nil)
     |> assign(:proxy_pid, nil)
     |> assign(:mode, :stream)
     |> assign(:show_status, true)
     |> assign(:format, "markdown")
     |> assign(:empty_message, "Click start to generate")
     |> assign(:class, nil)}
  end

  @impl true
  def update(assigns, socket) do
    component_id = assigns[:id] || socket.assigns[:id]
    Logger.debug("LivePrompt (ID: #{inspect(component_id)}) update called with assigns keys: #{inspect(Map.keys(assigns))}, action: #{inspect(assigns[:action])}")

    # Extract action BEFORE merging assigns
    action = assigns[:action]

    socket = assign(socket, assigns)

    Logger.debug("LivePrompt (ID: #{inspect(component_id)}) after merge, socket.assigns has: response=#{String.length(socket.assigns.response)} chars, status=#{socket.assigns.status}")

    # Handle external actions first
    socket =
      case action do
        :start ->
          Logger.debug("LivePrompt (ID: #{inspect(component_id)}): Starting prompt")
          start_prompt(socket)

        :cancel ->
          Logger.debug("LivePrompt: Cancelling prompt")
          cancel_prompt(socket)

        :reset ->
          Logger.debug("LivePrompt: Resetting prompt")
          reset_prompt(socket)

        _ ->
          socket
      end

    # Handle PubSub actions (sent from helper)
    socket = case assigns[:pubsub_action] do
      :connected ->
        Logger.debug("LivePrompt: Handling connected via PubSub")
        assign(socket, :status, :connected)

      :chunk ->
        if chunk = assigns[:chunk] do
          Logger.debug("LivePrompt: Handling chunk via PubSub: #{String.length(chunk)} chars")
          socket
          |> assign(:status, :streaming)
          |> update(:response, &(&1 <> chunk))
        else
          socket
        end

      :done ->
        if response = assigns[:response] do
          Logger.debug("LivePrompt: Handling done via PubSub")
          # Call completion callback if provided
          if callback = socket.assigns[:on_complete] do
            try do
              callback.(response)
            rescue
              e ->
                Logger.error("Error in on_complete callback: #{inspect(e)}")
            end
          end

          socket
          |> assign(:status, :done)
          |> assign(:task, nil)
        else
          socket
        end

      :error ->
        if error = assigns[:error] do
          Logger.debug("LivePrompt: Handling error via PubSub: #{inspect(error)}")
          # Call error callback if provided
          if callback = socket.assigns[:on_error] do
            try do
              callback.(error)
            rescue
              e ->
                Logger.error("Error in on_error callback: #{inspect(e)}")
            end
          end

          socket
          |> assign(:status, :error)
          |> assign(:error, error)
          |> assign(:task, nil)
        else
          socket
        end

      _ ->
        socket
    end

    # Auto-start if requested (and not already started)
    socket =
      if assigns[:auto_start] && socket.assigns.status == :idle do
        Logger.debug("LivePrompt: Auto-starting")
        start_prompt(socket)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("start", _params, socket) do
    {:noreply, start_prompt(socket)}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, cancel_prompt(socket)}
  end

  def handle_event("reset", _params, socket) do
    {:noreply, reset_prompt(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <WishSdk.Components.Response.wish_response
        content={@response}
        status={@status}
        error={@error}
        show_status={@show_status}
        format={@format}
        empty_message={@empty_message}
      />
    </div>
    """
  end

  # Private functions

  defp start_prompt(socket) do
    # Don't start if already running
    if socket.assigns.status in [:connecting, :streaming] do
      socket
    else
      mode = socket.assigns[:mode] || :stream

      # Get component ID and LiveView PID
      component_id = socket.assigns.id
      liveview_pid = self()

      Logger.debug("LivePrompt #{component_id}: Starting, will send messages to #{inspect(liveview_pid)}")

      # Extract slug and context from either direct assignment or struct
      {slug, context_variables} =
        case {socket.assigns[:prompt], socket.assigns[:slug]} do
          {%_module{} = prompt_struct, _} ->
            # Using generated struct
            {slug, opts} = WishSdk.Prompt.to_opts(prompt_struct)
            context = Keyword.get(opts, :context_variables, %{})
            {slug, context}

          {nil, slug} when is_binary(slug) ->
            # Using slug directly
            context = socket.assigns[:context_variables] || %{}
            {slug, context}

          _ ->
            Logger.error("LivePrompt: Must provide either :slug or :prompt")
            send(liveview_pid, {:live_prompt_error, component_id, %{message: "Must provide either :slug or :prompt"}})
            {nil, %{}}
        end

      if slug do
        user_prompt = socket.assigns[:user_prompt]

        opts = [
          context_variables: context_variables,
          on_chunk: fn chunk ->
            send(liveview_pid, {:live_prompt_chunk, component_id, chunk})
          end,
          on_done: fn response ->
            Logger.debug("LivePrompt #{component_id}: Sending done message")
            send(liveview_pid, {:live_prompt_done, component_id, response})
          end,
          on_error: fn error ->
            Logger.debug("LivePrompt #{component_id}: Sending error message: #{inspect(error)}")
            send(liveview_pid, {:live_prompt_error, component_id, error})
          end,
          on_connected: fn ->
            send(liveview_pid, {:live_prompt_connected, component_id})
          end
        ]

        opts = if user_prompt, do: Keyword.put(opts, :user_prompt, user_prompt), else: opts

        # Copy api_url and api_token if provided
        opts =
          socket.assigns
          |> Map.take([:api_url, :api_token])
          |> Enum.reduce(opts, fn {k, v}, acc ->
            if v, do: Keyword.put(acc, k, v), else: acc
          end)

        task =
          case mode do
            :stream ->
              {:ok, task} = WishSdk.stream(slug, opts)
              task

            :invoke ->
              Task.async(fn ->
                # Remove streaming-specific opts for invoke
                invoke_opts =
                  opts
                  |> Keyword.delete(:on_chunk)
                  |> Keyword.delete(:on_connected)

                case WishSdk.invoke(slug, invoke_opts) do
                  {:ok, response} ->
                    send(liveview_pid, {:live_prompt_done, component_id, response})

                  {:error, error} ->
                    send(liveview_pid, {:live_prompt_error, component_id, error})
                end
              end)
          end

        socket
        |> assign(:task, task)
        |> assign(:status, :connecting)
        |> assign(:error, nil)
      else
        socket
      end
    end
  end

  defp cancel_prompt(socket) do
    if task = socket.assigns.task do
      Task.shutdown(task, :brutal_kill)
    end

    socket
    |> assign(:task, nil)
    |> assign(:status, :cancelled)
  end

  defp reset_prompt(socket) do
    if task = socket.assigns.task do
      Task.shutdown(task, :brutal_kill)
    end

    socket
    |> assign(:task, nil)
    |> assign(:status, :idle)
    |> assign(:response, "")
    |> assign(:error, nil)
  end
end
