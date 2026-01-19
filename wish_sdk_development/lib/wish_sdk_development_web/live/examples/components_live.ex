defmodule WishSdkDevelopmentWeb.Examples.ComponentsLive do
  @moduledoc """
  LiveView components showcase.

  This page demonstrates WishSdk components with interactive demos.
  It uses `WishSdk.Api.Stub` directly (not `WishSdk`) to ensure demos
  always work without a real API connection, even in production.

  Other example pages (InvokeLive, StreamLive) use the real client.
  """
  use WishSdkDevelopmentWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:invoke_response, "")
     |> assign(:invoke_status, :idle)
     |> assign(:stream_response, "")
     |> assign(:stream_status, :idle)
     |> assign(
       :demo_response,
       "This is a sample AI response. In a real application, this would be populated by streaming from the Wish API via your Elixir backend."
     )
     |> assign(
       :demo_markdown,
       """
       # Markdown Example

       This component renders **markdown** with *formatting*.

       - Bullet lists
       - Code: `inline code`
       - Links and more

       ```elixir
       # Code blocks with syntax
       WishSdk.invoke(prompt)
       ```
       """
     )}
  end

  @impl true
  def handle_event("start_invoke_demo", _params, socket) do
    socket = assign(socket, invoke_response: "", invoke_status: :connecting)
    liveview_pid = self()

    Task.async(fn ->
      # Configure stub response INSIDE the task (process dictionary is per-process!)
      WishSdk.Api.Stub.set_response(
        "demo-invoke",
        "**Complete Response**\n\nThis is a simulated invoke response using `WishSdk.Api.Stub`. In a real application, this would come from `WishSdk.invoke(prompt)`.\n\n- Faster for shorter responses\n- Single HTTP request\n- Simpler error handling"
      )

      # Simulate API delay
      Process.sleep(1500)

      # Use Stub directly (not WishSdk) so this demo always uses stubs
      case WishSdk.Api.Stub.invoke("demo-invoke") do
        {:ok, response} -> send(liveview_pid, {:invoke_done, response})
        {:error, reason} -> send(liveview_pid, {:invoke_error, reason})
      end
    end)

    {:noreply, socket}
  end

  def handle_event("start_stream_demo", _params, socket) do
    socket = assign(socket, stream_response: "", stream_status: :streaming)
    liveview_pid = self()

    # Start streaming in a separate task
    Task.async(fn ->
      # Configure stub stream INSIDE the task
      WishSdk.Api.Stub.set_stream(
        "demo-stream",
        [
          "**Streaming Response**\n\n",
          "This is ",
          "a simulated ",
          "progressive ",
          "streaming response. ",
          "Notice how it appears ",
          "word by word!\n\n",
          "- Great for LLM responses\n",
          "- Real-time feedback\n",
          "- Better UX"
        ],
        chunk_delay: 150
      )

      # Use Stub directly (not WishSdk) so this demo always uses stubs
      {:ok, stream_task} =
        WishSdk.Api.Stub.stream("demo-stream",
          on_chunk: fn chunk -> send(liveview_pid, {:stream_chunk, chunk}) end,
          on_done: fn _ -> send(liveview_pid, :stream_done) end
        )

      Task.await(stream_task)
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:invoke_done, response}, socket) do
    {:noreply, assign(socket, invoke_response: response, invoke_status: :done)}
  end

  def handle_info({:invoke_error, error}, socket) do
    error_msg = "Error: #{inspect(error)}"
    {:noreply, assign(socket, invoke_response: error_msg, invoke_status: :error)}
  end

  def handle_info({:stream_chunk, chunk}, socket) do
    {:noreply, update(socket, :stream_response, &(&1 <> chunk))}
  end

  def handle_info(:stream_done, socket) do
    {:noreply, assign(socket, :stream_status, :done)}
  end

  # Catch-all for Task completion messages
  def handle_info({ref, _result}, socket) when is_reference(ref) do
    {:noreply, socket}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
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

      <h1 class="text-4xl font-bold mb-4">LiveView Components Example</h1>
      <p class="text-gray-600 mb-8">
        WishSdk provides 3 pre-built LiveView components:
        <code class="bg-gray-100 px-2 py-1 rounded mx-1">wish_response</code>
        <code class="bg-gray-100 px-2 py-1 rounded mx-1">wish_prompt</code>
        <code class="bg-gray-100 px-2 py-1 rounded mx-1">wish_status</code>
      </p>


      <div class="space-y-4 mb-8">
        <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
          <p class="text-purple-800">
            <strong>🎯 Type-Safe:</strong>
            Use generated structs with
            <code class="bg-purple-100 px-2 py-1 rounded">@enforce_keys</code>
            for
            compile-time safety and pattern matching in your LiveView!
          </p>
        </div>
      </div>

      <div class="space-y-12">
        <!-- Prompt Component - Invoke Example -->
        <div>
          <h2 class="text-2xl font-semibold mb-4">1. Prompt Component - Invoke Pattern</h2>
          <p class="text-gray-600 mb-4">
            Simple one-shot request/response pattern. Perfect for non-streaming use cases.
          </p>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-6">
            <div class="space-y-6">
            <!-- LiveView Code -->
            <div>
              <h3 class="text-lg font-semibold mb-3">LiveView Code:</h3>
              <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>
                # In your LiveView module
                alias MyApp.Prompts.MedicalSummary

                def handle_event("invoke", params, socket) do
                  # Build prompt struct (compile-time safe!)
                  prompt = %MedicalSummary{
                    case_id: params["case_id"],
                    document_id: params["document_id"]
                  }

                  # Show loading state
                  socket = assign(socket, response: "", status: :connecting)

                  # Invoke in background task
                  Task.async(fn -&gt;
                    case WishSdk.invoke(prompt) do
                      {:ok, response} -&gt;
                        send(self(), {:invoke_done, response})
                      {:error, reason} -&gt;
                        send(self(), {:invoke_error, reason})
                    end
                  end)

                  {:noreply, socket}
                end

                def handle_info({:invoke_done, response}, socket) do
                  {:noreply, assign(socket, response: response, status: :done)}
                end

                def handle_info({:invoke_error, error}, socket) do
                  {:noreply, assign(socket, response: "", status: :error)}
                end
              </code></pre>
            </div>

            <!-- HEEx Template -->
            <div>
              <h3 class="text-lg font-semibold mb-3">HEEx Template:</h3>
              <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>
                &lt;!-- In your .heex template --&gt;
                &lt;.wish_prompt
                  response={@response}
                  status={@status}
                /&gt;

                &lt;!-- Or use wish_response for more control --&gt;
                &lt;.wish_status status={@status} /&gt;
                &lt;.wish_response
                  content={@response}
                  loading={@status == :connecting}
                /&gt;
              </code></pre>
            </div>
            </div>

            <!-- Live Demo -->
            <div>
              <h3 class="text-lg font-semibold mb-3">Live Demo:</h3>
              <div class="border border-gray-300 rounded-lg p-4 bg-white">
                <button
                  phx-click="start_invoke_demo"
                  class="mb-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition"
                >
                  Start Invoke Demo
                </button>
                <.wish_prompt response={@invoke_response} status={@invoke_status} />
              </div>
            </div>
          </div>
        </div>

        <!-- Prompt Component - Stream Example -->
        <div>
          <h2 class="text-2xl font-semibold mb-4">2. Prompt Component - Stream Pattern</h2>
          <p class="text-gray-600 mb-4">
            Real-time streaming with progressive response updates. Great for LLM interactions.
          </p>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <div class="space-y-6">
              <!-- LiveView Code -->
              <div>
                <h3 class="text-lg font-semibold mb-3">LiveView Code:</h3>
                <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>
                # In your LiveView module
                alias MyApp.Prompts.MedicalSummary

                def handle_event("stream", params, socket) do
                  # Build prompt struct
                  prompt = %MedicalSummary{
                    case_id: params["case_id"],
                    document_id: params["document_id"]
                  }

                  socket = assign(socket,
                    response: "",
                    status: :streaming
                  )

                  # Stream with callbacks
                  {:ok, _task} = WishSdk.stream(prompt,
                    on_chunk: fn chunk -&gt;
                      send(self(), {:chunk, chunk})
                    end,
                    on_done: fn _ -&gt;
                      send(self(), :done)
                    end
                  )

                  {:noreply, socket}
                end

                def handle_info({:chunk, chunk}, socket) do
                  {:noreply,
                    update(socket, :response, &amp;(&amp;1 &lt;&gt; chunk))}
                end

                def handle_info(:done, socket) do
                  {:noreply, assign(socket, status: :done)}
                end
              </code></pre>
              </div>

              <!-- HEEx Template -->
              <div>
                <h3 class="text-lg font-semibold mb-3">HEEx Template:</h3>
                <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>
                &lt;!-- In your .heex template --&gt;
                &lt;.wish_prompt
                  response={@response}
                  status={@status}
                  auto_scroll={true}
                /&gt;

                &lt;!-- Alternative: Compose manually --&gt;
                &lt;.wish_status status={@status} /&gt;
                &lt;.wish_response
                  content={@response}
                  streaming={@status == :streaming}
                  auto_scroll={true}
                /&gt;
              </code></pre>
              </div>
            </div>

            <!-- Live Demo -->
            <div>
              <h3 class="text-lg font-semibold mb-3">Live Demo:</h3>
              <div class="border border-gray-300 rounded-lg p-4 bg-white">
                <button
                  phx-click="start_stream_demo"
                  class="mb-4 px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition"
                >
                  Start Stream Demo
                </button>
                <.wish_prompt response={@stream_response} status={@stream_status} auto_scroll={true} />
              </div>
            </div>
          </div>
        </div>
        <!-- Response Component Example -->
        <div>
          <h2 class="text-2xl font-semibold mb-4">Response Component</h2>
          <p class="text-gray-600 mb-4">
            Displays formatted responses with support for markdown (default), plain text, and HTML.
          </p>

          <div class="space-y-6">
            <!-- Markdown Format (Default) -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <div>
                <h3 class="text-lg font-semibold mb-3">Markdown (Default):</h3>
                <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code># Markdown is the default
    .wish_response content={@response}

    # With streaming cursor
    .wish_response
    content={@response}
    streaming={true}</code></pre>
                <p class="text-sm text-gray-600 mt-2">
                  Renders markdown with Earmark, supports GFM, code blocks, and streaming cursor.
                </p>
              </div>

              <div>
                <h3 class="text-lg font-semibold mb-3">Demo:</h3>
                <div class="border border-gray-300 rounded-lg bg-white p-4">
                  <.wish_response content={@demo_markdown} />
                </div>
              </div>
            </div>
            <!-- Plain Text Format -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <div>
                <h3 class="text-lg font-semibold mb-3">Plain Text:</h3>
                <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>.wish_response
    content={@response}
    format="text"</code></pre>
              </div>

              <div>
                <h3 class="text-lg font-semibold mb-3">Demo:</h3>
                <div class="border border-gray-300 rounded-lg bg-white p-4">
                  <.wish_response content={@demo_response} format="text" />
                </div>
              </div>
            </div>
            <!-- Loading State -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <div>
                <h3 class="text-lg font-semibold mb-3">Loading State with Sizes:</h3>
                <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code># Small
    .wish_response content="" loading={true} size="small"

    # Medium (default)
    .wish_response content="" loading={true} size="medium"

    # Large
    .wish_response content="" loading={true} size="large"</code></pre>
              </div>

              <div>
                <h3 class="text-lg font-semibold mb-3">Demo:</h3>
                <div class="border border-gray-300 rounded-lg bg-white space-y-4">
                  <div>
                    <p class="text-xs text-gray-500 mb-2 px-4 pt-4">Small:</p>
                    <.wish_response content="" loading={true} size="small" />
                  </div>
                  <div>
                    <p class="text-xs text-gray-500 mb-2 px-4">Medium (default):</p>
                    <.wish_response content="" loading={true} size="medium" />
                  </div>
                  <div>
                    <p class="text-xs text-gray-500 mb-2 px-4">Large:</p>
                    <.wish_response content="" loading={true} size="large" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <!-- Status Component Example -->
        <div>
          <h2 class="text-2xl font-semibold mb-4">Status Component</h2>
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <div>
              <h3 class="text-lg font-semibold mb-3">Component Code:</h3>
              <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code># Use wish_status component
    .wish_status
    status={:streaming}
    message="Generating response..."</code></pre>
            </div>

            <div>
              <h3 class="text-lg font-semibold mb-3">Demo:</h3>
              <div class="space-y-3">
                <.wish_status status={:idle} />
                <.wish_status status={:connecting} />
                <.wish_status status={:connected} />
                <.wish_status status={:streaming} message="Generating response..." />
                <.wish_status status={:done} />
                <.wish_status status={:error} message="Connection failed" />
              </div>
            </div>
          </div>
        </div>
        <!-- Key Benefits -->
        <div class="bg-gradient-to-r from-green-50 to-blue-50 border border-green-200 rounded-lg p-6">
          <h2 class="text-2xl font-semibold mb-4">✨ Benefits of Pure Elixir Approach</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <h4 class="font-semibold text-green-900 mb-2">🔒 Secure</h4>
              <p class="text-sm text-gray-700">
                API keys and credentials stay on the server, never exposed to the browser
              </p>
            </div>
            <div>
              <h4 class="font-semibold text-green-900 mb-2">🚀 Simple</h4>
              <p class="text-sm text-gray-700">
                No complex JavaScript needed - just plain Elixir code
              </p>
            </div>
            <div>
              <h4 class="font-semibold text-green-900 mb-2">🎯 Reliable</h4>
              <p class="text-sm text-gray-700">
                LiveView handles connection issues, reconnection, and state sync automatically
              </p>
            </div>
            <div>
              <h4 class="font-semibold text-green-900 mb-2">🧪 Testable</h4>
              <p class="text-sm text-gray-700">
                Test your streaming logic with standard Elixir testing tools
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
