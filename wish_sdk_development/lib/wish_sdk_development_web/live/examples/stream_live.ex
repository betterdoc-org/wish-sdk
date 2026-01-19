defmodule WishSdkDevelopmentWeb.Examples.StreamLive do
  use WishSdkDevelopmentWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:slug, "")
     |> assign(:context_variables, "{\n  \"case_id\": \"123\"\n}")
     |> assign(:user_prompt, "")
     |> assign(:response, "")
     |> assign(:error, nil)
     |> assign(:streaming, false)
     |> assign(:status, :idle)}
  end

  @impl true
  def handle_event("stream", %{"slug" => slug, "context" => context, "prompt" => prompt}, socket) do
    require Logger
    Logger.info("Starting stream for slug: #{slug}")

    # Persist user input values
    socket =
      socket
      |> assign(:slug, slug)
      |> assign(:context_variables, context)
      |> assign(:user_prompt, prompt)
      |> assign(:streaming, true)
      |> assign(:status, :connecting)
      |> assign(:error, nil)
      |> assign(:response, "")

    context_vars =
      case Jason.decode(context) do
        {:ok, vars} ->
          Logger.info("Parsed context: #{inspect(vars)}")
          vars

        {:error, e} ->
          Logger.error("Failed to parse context JSON: #{inspect(e)}")
          %{}
      end

    opts = [context_variables: context_vars]
    opts = if prompt != "", do: Keyword.put(opts, :user_prompt, prompt), else: opts

    # Capture the LiveView process PID
    liveview_pid = self()
    Logger.info("LiveView PID: #{inspect(liveview_pid)}")

    opts =
      Keyword.merge(opts,
        on_connected: fn ->
          Logger.info("Stream connected, sending to #{inspect(liveview_pid)}")
          send(liveview_pid, {:status, :connected})
        end,
        on_chunk: fn chunk ->
          Logger.debug(
            "Received chunk: #{String.slice(chunk, 0, 50)}..., sending to #{inspect(liveview_pid)}"
          )

          send(liveview_pid, {:chunk, chunk})
        end,
        on_done: fn response ->
          Logger.info("Stream done, sending to #{inspect(liveview_pid)}")
          send(liveview_pid, {:done, response})
        end,
        on_error: fn error ->
          Logger.error("Stream error: #{inspect(error)}, sending to #{inspect(liveview_pid)}")
          send(liveview_pid, {:error, error})
        end
      )

    case WishSdk.stream(slug, opts) do
      {:ok, _task} ->
        Logger.info("Stream task started successfully")
        {:noreply, socket}

      {:error, error} ->
        Logger.error("Failed to start stream: #{inspect(error)}")

        {:noreply,
         socket
         |> assign(:streaming, false)
         |> assign(:status, :error)
         |> assign(:error, "Failed to start stream: #{inspect(error)}")}
    end
  end

  @impl true
  def handle_info({:status, status}, socket) do
    require Logger
    Logger.info("LiveView: Status update to #{status}")
    {:noreply, assign(socket, :status, status)}
  end

  def handle_info({:chunk, chunk}, socket) do
    new_socket =
      socket
      |> assign(:status, :streaming)
      |> update(:response, &(&1 <> chunk))

    {:noreply, new_socket}
  end

  def handle_info({:done, _response}, socket) do
    require Logger

    Logger.info(
      "LiveView: Stream done, final response length: #{String.length(socket.assigns.response)}"
    )

    {:noreply,
     socket
     |> assign(:streaming, false)
     |> assign(:status, :done)}
  end

  def handle_info({:error, error}, socket) do
    require Logger
    Logger.error("LiveView: Error in stream: #{inspect(error)}")

    {:noreply,
     socket
     |> assign(:streaming, false)
     |> assign(:status, :error)
     |> assign(:error, inspect(error))}
  end

  # Handle Task completion messages
  def handle_info({ref, :ok}, socket) when is_reference(ref) do
    # Task completed successfully
    {:noreply, socket}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    # Task process terminated
    {:noreply, socket}
  end

  # Catch-all for unexpected messages
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div class="mb-8">
        <.link navigate={~p"/"} class="text-blue-600 hover:text-blue-800">
          ← Back to Home
        </.link>
      </div>

      <h1 class="text-4xl font-bold mb-4">Stream API Example</h1>
      <p class="text-gray-600 mb-4">
        Demonstrates <code class="bg-gray-100 px-2 py-1 rounded">WishSdk.stream/2</code>
        for real-time streaming responses.
      </p>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div>
          <h2 class="text-2xl font-semibold mb-4">Configuration</h2>

          <form phx-submit="stream" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Prompt Slug
              </label>
              <input
                type="text"
                name="slug"
                value={@slug}
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                placeholder="medical-summary"
                required
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Context Variables (JSON)
              </label>
              <textarea
                name="context"
                rows="6"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 font-mono text-sm"
                required
              ><%= @context_variables %></textarea>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                User Prompt (optional)
              </label>
              <textarea
                name="prompt"
                rows="3"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                placeholder="What are the key findings?"
              ><%= @user_prompt %></textarea>
            </div>

            <button
              type="submit"
              disabled={@streaming}
              class="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              <%= if @streaming, do: "Streaming...", else: "Start Streaming" %>
            </button>
          </form>

          <div class="mt-6 space-y-4">
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="font-semibold mb-2">Code (Raw API):</h3>
              <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>WishSdk.stream("<%= @slug %>",
    context_variables: <%= @context_variables %>,
    on_chunk: fn chunk -> IO.write(chunk) end,
    on_done: fn response -> IO.puts("✓ Done") end
    )</code></pre>
            </div>

            <div class="bg-blue-50 rounded-lg p-4">
              <h3 class="font-semibold mb-2 text-blue-900">
                💡 Better: Use Generated Prompts
              </h3>
              <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code># After running: mix wish.gen.prompts
    alias MyApp.Prompts.MedicalSummary

    # Compile-time safe!
    %MedicalSummary{case_id: "123", document_id: "456"}
    |> WishSdk.stream(
    on_chunk: fn chunk -> IO.write(chunk) end,
    on_done: fn _ -> IO.puts("✓ Done") end
    )</code></pre>
              <p class="text-sm text-blue-800 mt-2">
                See the
                <.link navigate={~p"/examples/generated"} class="underline hover:text-blue-600">
                  Generated Modules
                </.link>
                example to learn more.
              </p>
            </div>
          </div>
        </div>

        <div>
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-2xl font-semibold">Response</h2>
            <.wish_status status={@status} />
          </div>

          <%= if @error do %>
            <div class="bg-red-50 border border-red-200 rounded-lg p-4">
              <h3 class="text-red-900 font-semibold mb-2">Error</h3>
              <pre class="text-sm text-red-800 whitespace-pre-wrap"><%= @error %></pre>
            </div>
          <% end %>

          <%= if @response != "" do %>
            <div class="bg-white border border-gray-200 rounded-lg p-6 min-h-[200px] max-h-[500px] overflow-auto">
              <.wish_response content={@response} streaming={@streaming} auto_scroll={true} />
            </div>
          <% else %>
            <div class="bg-gray-50 border border-gray-200 rounded-lg p-6 text-center text-gray-500 min-h-[200px] flex items-center justify-center">
              <%= if @streaming do %>
                <div class="text-blue-600">
                  <svg
                    class="animate-spin h-8 w-8 mx-auto mb-2"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    >
                    </circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    >
                    </path>
                  </svg>
                  <p>Waiting for stream...</p>
                </div>
              <% else %>
                Enter configuration and click "Start Streaming" to see results
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
