defmodule WishSdkDevelopmentWeb.Examples.LivePromptLive do
  use WishSdkDevelopmentWeb, :live_view
  use WishSdk.Components.LivePromptHelper  # <- ONE LINE enables LivePrompt components!

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:slug, "latest")
     |> assign(:context_variables, %{"case_id" => "123"})
     |> assign(:user_prompt, "")
     |> assign(:saved_response, nil)
     |> assign(:completion_count, 0)}
  end

  @impl true
  def handle_event("update_slug", %{"slug" => slug}, socket) do
    {:noreply, assign(socket, :slug, slug)}
  end

  def handle_event("update_context", %{"context" => context}, socket) do
    case Jason.decode(context) do
      {:ok, vars} -> {:noreply, assign(socket, :context_variables, vars)}
      {:error, _} -> {:noreply, socket}
    end
  end

  def handle_event("start_prompt", %{"id" => id}, socket) do
    send_update(WishSdk.Components.LivePrompt, id: id, action: :start)
    {:noreply, socket}
  end

  def handle_event("start_all", _params, socket) do
    send_update(WishSdk.Components.LivePrompt, id: "multi-prompt-1", action: :start)
    send_update(WishSdk.Components.LivePrompt, id: "multi-prompt-2", action: :start)
    send_update(WishSdk.Components.LivePrompt, id: "multi-prompt-3", action: :start)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:ai_complete, response}, socket) do
    # Example of handling completion in parent LiveView
    {:noreply,
     socket
     |> assign(:saved_response, String.slice(response, 0, 100) <> "...")
     |> update(:completion_count, &(&1 + 1))
     |> put_flash(:info, "AI response received and processed!")}
  end

  # Delegate all other messages to the LivePromptHelper
  def handle_info(msg, socket) do
    handle_live_prompt_message(msg, socket)
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

      <h1 class="text-4xl font-bold mb-4">LivePrompt Component</h1>
      <p class="text-gray-600 mb-8">
        <strong>Zero boilerplate!</strong>
        The
        <code class="bg-gray-100 px-2 py-1 rounded">WishSdk.Components.LivePrompt</code>
        component handles all state and message management internally.
      </p>

      <!-- Comparison Banner -->
      <div class="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-6 mb-8">
        <div class="flex items-start space-x-4">
          <div class="flex-shrink-0">
            <svg
              class="w-8 h-8 text-blue-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 10V3L4 14h7v7l9-11h-7z"
              />
            </svg>
          </div>
          <div class="flex-1">
            <h3 class="text-lg font-semibold text-gray-900 mb-2">
              🎉 Dramatically Simplified API
            </h3>
            <p class="text-gray-700 mb-4">
              Compare the
              <.link navigate={~p"/examples/stream"} class="text-blue-600 hover:underline">
                low-level streaming example
              </.link>
              (~50+ lines of boilerplate) to this high-level component (just 3 lines!).
            </p>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div class="bg-white rounded p-3 border border-gray-200">
                <div class="font-semibold text-red-700 mb-2">❌ Low-Level (50+ lines)</div>
                <ul class="text-gray-600 space-y-1 text-xs">
                  <li>• Manual state management</li>
                  <li>• Define 4+ callbacks</li>
                  <li>• Handle 5+ message types</li>
                  <li>• Task cleanup boilerplate</li>
                </ul>
              </div>
              <div class="bg-white rounded p-3 border border-green-200">
                <div class="font-semibold text-green-700 mb-2">✅ High-Level (3 lines)</div>
                <ul class="text-gray-600 space-y-1 text-xs">
                  <li>• Zero boilerplate</li>
                  <li>• Self-managing state</li>
                  <li>• Optional callbacks</li>
                  <li>• Automatic cleanup</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Example 1: Auto-start -->
      <div class="mb-12">
        <h2 class="text-2xl font-semibold mb-4">1. Auto-Start (Simplest)</h2>
        <p class="text-gray-600 mb-4">
          Component starts streaming immediately when mounted. Perfect for pre-configured prompts.
        </p>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div>
            <h3 class="font-semibold mb-2">Code:</h3>
            <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>&lt;.live_component
  module={WishSdk.Components.LivePrompt}
  id="auto-prompt"
  slug="<%= @slug %>"
  context_variables={%{"case_id" => "123"}}
  auto_start={true}
/&gt;</code></pre>
          </div>

          <div>
            <h3 class="font-semibold mb-2">Live Result:</h3>
            <.live_component
              module={WishSdk.Components.LivePrompt}
              id="auto-prompt"
              slug={@slug}
              context_variables={@context_variables}
              auto_start={true}
              class="bg-white border border-gray-200 rounded-lg p-4"
            />
          </div>
        </div>
      </div>

      <!-- Example 2: Manual Control -->
      <div class="mb-12">
        <h2 class="text-2xl font-semibold mb-4">2. Manual Control</h2>
        <p class="text-gray-600 mb-4">
          User clicks a button to start generation. Component handles everything else.
        </p>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div>
            <h3 class="font-semibold mb-2">Code:</h3>
            <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>&lt;button phx-click="start_prompt" phx-value-id="manual-prompt"&gt;
  Generate Summary
&lt;/button&gt;

&lt;.live_component
  module={WishSdk.Components.LivePrompt}
  id="manual-prompt"
  slug="<%= @slug %>"
  context_variables={%{"case_id" => "456"}}
/&gt;

# In LiveView:
def handle_event("start_prompt", %{"id" => id}, socket) do
  send_update(WishSdk.Components.LivePrompt, id: id, action: :start)
  {:noreply, socket}
end</code></pre>
          </div>

          <div>
            <h3 class="font-semibold mb-2">Live Result:</h3>
            <button
              phx-click="start_prompt"
              phx-value-id="manual-prompt"
              class="mb-4 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              🚀 Generate Summary
            </button>

            <.live_component
              module={WishSdk.Components.LivePrompt}
              id="manual-prompt"
              slug={@slug}
              context_variables={Map.merge(@context_variables, %{"case_id" => "456"})}
              empty_message="Click the button above to start generation"
              class="bg-white border border-gray-200 rounded-lg p-4"
            />
          </div>
        </div>
      </div>

      <!-- Example 3: With Completion Callback -->
      <div class="mb-12">
        <h2 class="text-2xl font-semibold mb-4">3. Completion Callback</h2>
        <p class="text-gray-600 mb-4">
          Get notified when generation completes. Perfect for saving to database, updating state, etc.
        </p>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div>
            <h3 class="font-semibold mb-2">Code:</h3>
            <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>&lt;.live_component
  module={WishSdk.Components.LivePrompt}
  id="callback-prompt"
  slug="<%= @slug %>"
  context_variables={%{"case_id" => "789"}}
  on_complete={fn response ->
    send(self(), {:ai_complete, response})
  end}
/&gt;

# In LiveView:
def handle_info({:ai_complete, response}, socket) do
  # Save to DB, update state, etc.
  {:noreply, put_flash(socket, :info, "Saved!")}
end</code></pre>

            <div :if={@saved_response} class="mt-4 p-3 bg-green-50 border border-green-200 rounded">
              <div class="font-semibold text-green-800 text-sm">
                ✅ Completion callbacks fired: <%= @completion_count %>
              </div>
              <div class="text-xs text-green-700 mt-1">
                Last response: <%= @saved_response %>
              </div>
            </div>
          </div>

          <div>
            <h3 class="font-semibold mb-2">Live Result:</h3>
            <button
              phx-click="start_prompt"
              phx-value-id="callback-prompt"
              class="mb-4 px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
            >
              Generate & Notify Parent
            </button>

            <.live_component
              module={WishSdk.Components.LivePrompt}
              id="callback-prompt"
              slug={@slug}
              context_variables={Map.merge(@context_variables, %{"case_id" => "789"})}
              on_complete={fn response -> send(self(), {:ai_complete, response}) end}
              empty_message="Click above to see callback in action"
              class="bg-white border border-gray-200 rounded-lg p-4"
            />
          </div>
        </div>
      </div>

      <!-- Example 4: Multiple Prompts -->
      <div class="mb-12">
        <h2 class="text-2xl font-semibold mb-4">4. Multiple Prompts (Parallel)</h2>
        <p class="text-gray-600 mb-4">
          Run multiple prompts simultaneously. Each manages its own state independently.
        </p>

        <div class="mb-4">
          <button
            phx-click="start_all"
            class="px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700"
          >
            🚀 Generate All Three
          </button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <h3 class="font-semibold mb-2 text-sm">Prompt 1</h3>
            <.live_component
              module={WishSdk.Components.LivePrompt}
              id="multi-prompt-1"
              slug={@slug}
              context_variables={Map.merge(@context_variables, %{"case_id" => "A"})}
              empty_message="Waiting..."
              class="bg-white border border-gray-200 rounded-lg p-3 text-sm"
            />
          </div>

          <div>
            <h3 class="font-semibold mb-2 text-sm">Prompt 2</h3>
            <.live_component
              module={WishSdk.Components.LivePrompt}
              id="multi-prompt-2"
              slug={@slug}
              context_variables={Map.merge(@context_variables, %{"case_id" => "B"})}
              empty_message="Waiting..."
              class="bg-white border border-gray-200 rounded-lg p-3 text-sm"
            />
          </div>

          <div>
            <h3 class="font-semibold mb-2 text-sm">Prompt 3</h3>
            <.live_component
              module={WishSdk.Components.LivePrompt}
              id="multi-prompt-3"
              slug={@slug}
              context_variables={Map.merge(@context_variables, %{"case_id" => "C"})}
              empty_message="Waiting..."
              class="bg-white border border-gray-200 rounded-lg p-3 text-sm"
            />
          </div>
        </div>
      </div>

      <!-- Example 5: Invoke Mode (Non-Streaming) -->
      <div class="mb-12">
        <h2 class="text-2xl font-semibold mb-4">5. Invoke Mode (Non-Streaming)</h2>
        <p class="text-gray-600 mb-4">
          Use <code class="bg-gray-100 px-2 py-1 rounded">mode={:invoke}</code>
          for a single complete response (no streaming).
        </p>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div>
            <h3 class="font-semibold mb-2">Code:</h3>
            <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>&lt;.live_component
  module={WishSdk.Components.LivePrompt}
  id="invoke-prompt"
  slug="<%= @slug %>"
  context_variables={%{"case_id" => "999"}}
  mode={:invoke}
/&gt;</code></pre>
          </div>

          <div>
            <h3 class="font-semibold mb-2">Live Result:</h3>
            <button
              phx-click="start_prompt"
              phx-value-id="invoke-prompt"
              class="mb-4 px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
            >
              Invoke (Non-Streaming)
            </button>

            <.live_component
              module={WishSdk.Components.LivePrompt}
              id="invoke-prompt"
              slug={@slug}
              context_variables={Map.merge(@context_variables, %{"case_id" => "999"})}
              mode={:invoke}
              empty_message="Click above to invoke (waits for complete response)"
              class="bg-white border border-gray-200 rounded-lg p-4"
            />
          </div>
        </div>
      </div>

      <!-- When to Use Low-Level API -->
      <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-6 mb-8">
        <h2 class="text-xl font-semibold text-yellow-900 mb-3">
          🤔 When to Use the Low-Level API?
        </h2>
        <p class="text-gray-700 mb-3">
          Use the
          <.link navigate={~p"/examples/stream"} class="text-blue-600 hover:underline">
            low-level streaming API
          </.link>
          when you need:
        </p>
        <ul class="text-gray-700 space-y-2 ml-6 list-disc">
          <li>
            <strong>Complex state coordination</strong>
            - Multiple prompts affecting shared state
          </li>
          <li>
            <strong>Custom message handling</strong>
            - Special logic for each chunk/event
          </li>
          <li>
            <strong>Integration with existing systems</strong>
            - Broadcasting to channels, real-time updates to multiple clients
          </li>
          <li>
            <strong>Fine-grained control</strong>
            - Cancellation, retry logic, custom error recovery
          </li>
        </ul>
        <p class="text-gray-700 mt-3">
          For simple "invoke and display" use cases, this high-level component is perfect! 🎯
        </p>
      </div>

      <!-- API Reference -->
      <div class="bg-gray-50 border border-gray-200 rounded-lg p-6">
        <h2 class="text-xl font-semibold mb-3">📚 Component API Reference</h2>

        <div class="space-y-4 text-sm">
          <div>
            <code class="bg-gray-900 text-gray-100 px-2 py-1 rounded">id</code>
            <span class="text-red-600 ml-2">required</span>
            - Unique component ID
          </div>

          <div>
            <code class="bg-gray-900 text-gray-100 px-2 py-1 rounded">slug</code>
            or
            <code class="bg-gray-900 text-gray-100 px-2 py-1 rounded">prompt</code>
            <span class="text-red-600 ml-2">required</span>
            - Prompt slug or struct
          </div>

          <div>
            <code class="bg-gray-900 text-gray-100 px-2 py-1 rounded">context_variables</code>
            - Map of context variables
          </div>

          <div>
            <code class="bg-gray-900 text-gray-100 px-2 py-1 rounded">mode</code>
            - <code>:stream</code> (default) or <code>:invoke</code>
          </div>

          <div>
            <code class="bg-gray-900 text-gray-100 px-2 py-1 rounded">auto_start</code>
            - Start on mount (default: false)
          </div>

          <div>
            <code class="bg-gray-900 text-gray-100 px-2 py-1 rounded">on_complete</code>
            - Callback: <code>fn response -> ... end</code>
          </div>

          <div>
            <code class="bg-gray-900 text-gray-100 px-2 py-1 rounded">on_error</code>
            - Callback: <code>fn error -> ... end</code>
          </div>

          <div>
            <code class="bg-gray-900 text-gray-100 px-2 py-1 rounded">show_status</code>
            - Show status indicator (default: true)
          </div>

          <div>
            <code class="bg-gray-900 text-gray-100 px-2 py-1 rounded">format</code>
            - "text", "markdown" (default), "html"
          </div>

          <div>
            <code class="bg-gray-900 text-gray-100 px-2 py-1 rounded">empty_message</code>
            - Message when idle
          </div>

          <div>
            <code class="bg-gray-900 text-gray-100 px-2 py-1 rounded">class</code>
            - Additional CSS classes
          </div>
        </div>

        <div class="mt-6">
          <h3 class="font-semibold mb-2">Programmatic Control:</h3>
          <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code># Start
send_update(WishSdk.Components.LivePrompt, id: "my-prompt", action: :start)

# Cancel
send_update(WishSdk.Components.LivePrompt, id: "my-prompt", action: :cancel)

# Reset
send_update(WishSdk.Components.LivePrompt, id: "my-prompt", action: :reset)</code></pre>
        </div>
      </div>
    </div>
    """
  end
end
