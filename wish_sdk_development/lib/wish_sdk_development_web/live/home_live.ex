defmodule WishSdkDevelopmentWeb.HomeLive do
  use WishSdkDevelopmentWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div class="text-center mb-12">
        <div class="flex justify-center mb-6">
          <img src={~p"/images/logo.svg"} alt="WishSdk Logo" class="h-32 w-auto" />
        </div>
        <h1 class="text-5xl font-bold text-gray-900 mb-4">
          WishSdk
        </h1>
        <p class="text-xl text-gray-600 mb-8">
          Elixir SDK for seamless BetterPrompt AI integration
        </p>
        <div class="flex justify-center space-x-4">
          <a
            href="https://github.com/betterdoc-org/wish-sdk"
            class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
          >
            View on GitHub
          </a>
          <a
            href="https://hexdocs.pm/wish_sdk"
            class="inline-flex items-center px-6 py-3 border border-gray-300 text-base font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
          >
            Documentation
          </a>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-12">
        <div class="bg-white rounded-lg shadow-lg p-6">
          <div class="text-3xl mb-3">🚀</div>
          <h3 class="text-xl font-semibold mb-2">Simple API</h3>
          <p class="text-gray-600">
            Invoke prompts with <code class="bg-gray-100 px-2 py-1 rounded">WishSdk.invoke/2</code>
            or stream with <code class="bg-gray-100 px-2 py-1 rounded">WishSdk.stream/2</code>
          </p>
        </div>

        <div class="bg-white rounded-lg shadow-lg p-6">
          <div class="text-3xl mb-3">🔒</div>
          <h3 class="text-xl font-semibold mb-2">Type-Safe</h3>
          <p class="text-gray-600">
            Generate Ecto-based modules with validation for each prompt using Mix tasks
          </p>
        </div>

        <div class="bg-white rounded-lg shadow-lg p-6">
          <div class="text-3xl mb-3">📡</div>
          <h3 class="text-xl font-semibold mb-2">Streaming Support</h3>
          <p class="text-gray-600">
            Real-time streaming responses via Server-Sent Events with callbacks
          </p>
        </div>

        <div class="bg-white rounded-lg shadow-lg p-6">
          <div class="text-3xl mb-3">🎨</div>
          <h3 class="text-xl font-semibold mb-2">LiveView Components</h3>
          <p class="text-gray-600">
            Optional UI components for interactive prompts in Phoenix LiveView
          </p>
        </div>
      </div>

      <div class="bg-gray-50 rounded-lg p-8 mb-12">
        <h2 class="text-2xl font-bold mb-4">Quick Start (Type-Safe)</h2>
        <div class="bg-gray-900 text-gray-100 rounded-lg p-4 overflow-x-auto">
          <pre><code class="language-elixir"># Add to mix.exs
    {:wish_sdk, "~> 0.1.0"}

    # Configure
    config :wish_sdk,
    api_url: "https://your-wish-instance.com",
    api_token: "your-platform-token"  # Optional

    # Generate type-safe modules
    mix wish.gen.prompts

    # Use with compile-time safety!
    alias MyApp.Prompts.MedicalSummary

    %MedicalSummary{case_id: "123", document_id: "456"}
    |> WishSdk.invoke()

    # Stream with structs
    %MedicalSummary{case_id: "123", document_id: "456"}
    |> WishSdk.stream(
    on_chunk: fn chunk -> IO.write(chunk) end
    )</code></pre>
        </div>
      </div>

      <div class="mb-12">
        <h2 class="text-2xl font-bold mb-6 text-center">Interactive Examples</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <.link
            navigate={~p"/examples/invoke"}
            class="block bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow"
          >
            <h3 class="text-xl font-semibold mb-2">Invoke API</h3>
            <p class="text-gray-600">
              Simple synchronous invocation with complete response
            </p>
          </.link>

          <.link
            navigate={~p"/examples/stream"}
            class="block bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow"
          >
            <h3 class="text-xl font-semibold mb-2">Stream API (Low-Level)</h3>
            <p class="text-gray-600">
              Real-time streaming with manual callbacks and state management
            </p>
          </.link>

          <.link
            navigate={~p"/examples/live-prompt"}
            class="block bg-gradient-to-r from-blue-500 to-indigo-600 rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow text-white"
          >
            <div class="flex items-center justify-between mb-2">
              <h3 class="text-xl font-semibold">LivePrompt Component</h3>
              <span class="px-2 py-1 bg-white text-blue-600 text-xs font-bold rounded">NEW!</span>
            </div>
            <p class="text-blue-100">
              🎉 Zero-boilerplate streaming with self-managing component
            </p>
          </.link>

          <.link
            navigate={~p"/examples/components"}
            class="block bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow"
          >
            <h3 class="text-xl font-semibold mb-2">Display Components</h3>
            <p class="text-gray-600">
              Pre-built UI components for displaying AI responses
            </p>
          </.link>

          <.link
            navigate={~p"/examples/generated"}
            class="block bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow"
          >
            <h3 class="text-xl font-semibold mb-2">Generated Modules</h3>
            <p class="text-gray-600">
              Type-safe modules generated from API schema
            </p>
          </.link>
        </div>
      </div>


    </div>
    """
  end
end
