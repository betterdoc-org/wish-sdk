# WishSdk

**Elixir SDK for seamless BetterPrompt AI integration**

WishSdk is a thin Elixir client library that enables smooth integration of published BetterPrompts into your Elixir applications. It provides both simple function-based APIs and optional LiveView components.

## Features

- 🚀 **Simple API**: Invoke prompts with `WishSdk.invoke/2` or stream with `WishSdk.stream/2`
- 🔒 **Type-Safe**: Generate Ecto-based modules with validation for each prompt
- 📡 **Streaming Support**: Real-time streaming responses via Server-Sent Events
- 🎨 **LiveView Components**: Optional UI components for interactive prompts
- 🔧 **Mix Tasks**: Code generation from your Wish API schema
- 📚 **Well Documented**: Comprehensive docs and interactive showcase app

## Installation

Add `wish_sdk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:wish_sdk, "~> 0.1.0"}
  ]
end
```

## Configuration

Configure your Wish API endpoint and platform token in `config/config.exs`:

```elixir
config :wish_sdk,
  api_url: "https://your-wish-instance.com",
  api_token: "your-platform-token"
```

The `api_token` is sent as the `x-platform-internal-call-token` header for authenticated endpoints.

Or use environment variables:

```bash
export WISH_API_URL=https://your-wish-instance.com
export WISH_API_TOKEN=your-platform-token
```

## Quick Start

### 1. Generate Type-Safe Modules (Recommended)

First, generate compile-time safe modules for your prompts:

```bash
mix wish.gen.prompts
```

This creates modules with `@enforce_keys` for compile-time safety:

```elixir
defmodule MyApp.Prompts.MedicalSummary do
  use Ecto.Schema
  
  # Compile-time safety!
  @enforce_keys [:case_id, :document_id]
  
  embedded_schema do
    field :case_id, :string
    field :document_id, :string
  end
  
  def invoke(params, opts \\ [])
  def stream(params, opts \\ [])
end
```

### 2. Use with Compile-Time Safety

```elixir
alias MyApp.Prompts.MedicalSummary

# ✅ Compile-time safe - won't compile if fields are missing!
prompt = %MedicalSummary{
  case_id: "123",
  document_id: "456"
}

{:ok, response} = WishSdk.invoke(prompt)
IO.puts(response)
# => "The patient presents with..."

# Or use the module helper
{:ok, response} = MedicalSummary.invoke(
  case_id: "123",
  document_id: "456"
)
```

### 3. Streaming with Structs

```elixir
alias MyApp.Prompts.MedicalSummary

%MedicalSummary{case_id: "123", document_id: "456"}
|> WishSdk.stream(
  on_chunk: fn chunk -> IO.write(chunk) end,
  on_done: fn _ -> IO.puts("\n✓ Complete!") end,
  on_error: fn error -> IO.puts("Error: #{inspect(error)}") end
)
```

### Alternative: String-Based API (No Compile-Time Safety)

For prototyping or dynamic scenarios, you can use the string-based API:

```elixir
# ⚠️ No compile-time validation
{:ok, response} = WishSdk.invoke("medical-summary",
  context_variables: %{
    case_id: "123",
    document_id: "456"
  }
)
```

**Note**: This approach provides no compile-time safety. Typos and missing fields will only be caught at runtime.

## LiveView Integration (Pure Elixir)

WishSdk is designed to work seamlessly with Phoenix LiveView using **pure Elixir** - no JavaScript required!

### Setup

Import components in your `lib/my_app_web.ex`:

```elixir
defp html_helpers do
  quote do
    # ... other imports
    use WishSdk.Components
  end
end
```

### Using in LiveView

All API calls happen server-side in your LiveView process:

```elixir
defmodule MyAppWeb.PromptLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, response: "", status: :idle)}
  end

  def handle_event("invoke", _params, socket) do
    socket = assign(socket, status: :streaming, response: "")
    
    # Stream from Elixir backend
    {:ok, _task} = WishSdk.stream("medical-summary",
      context_variables: %{case_id: "123"},
      on_chunk: fn chunk -> send(self(), {:chunk, chunk}) end,
      on_done: fn response -> send(self(), {:done, response}) end,
      on_error: fn error -> send(self(), {:error, error}) end
    )
    
    {:noreply, socket}
  end

  def handle_info({:chunk, chunk}, socket) do
    {:noreply, update(socket, :response, &(&1 <> chunk))}
  end

  def handle_info({:done, _response}, socket) do
    {:noreply, assign(socket, :status, :done)}
  end

  def handle_info({:error, error}, socket) do
    {:noreply, socket |> assign(:status, :error) |> put_flash(:error, inspect(error))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <button phx-click="invoke">Generate Summary</button>
      <.wish_response content={@response} status={@status} show_status={true} />
    </div>
    """
  end
end
```

### Optional JavaScript Hooks

JavaScript hooks are **optional** and only provide UI enhancements like auto-scrolling. The SDK works perfectly without them!

If you want the optional hooks, copy the JavaScript file to your assets:

```bash
# Copy hooks from the installed package
cp deps/wish_sdk/priv/static/wish_sdk_hooks.js assets/vendor/
```

Then import in your `assets/js/app.js`:

```javascript
import WishHooks from "../vendor/wish_sdk_hooks";

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: WishHooks,  // Optional!
  params: {_csrf_token: csrfToken}
})
```

## Testing with Stubs

WishSdk uses **Knigge** for behavior delegation, making it easy to stub API calls in tests without needing actual API connections.

### Configuration

Enable stubs in your test configuration:

```elixir
# config/test.exs
config :wish_sdk, WishSdk.Api, WishSdk.Api.Stub
```

Once configured, **all** `WishSdk` calls automatically use the stub!

### Basic Usage

```elixir
# In your tests
setup do
  # Configure stub response for specific prompt
  WishSdk.Api.Stub.set_response("medical-summary", "Mocked response")
  
  # Configure streaming chunks
  WishSdk.Api.Stub.set_stream("patient-onboarding", ["Hello", " ", "world"])
  
  :ok
end

test "handles invoke response" do
  {:ok, response} = WishSdk.invoke("medical-summary")
  assert response == "Mocked response"
end

test "handles streaming" do
  {:ok, _task} = WishSdk.stream("patient-onboarding",
    on_chunk: fn chunk -> send(self(), {:chunk, chunk}) end
  )
  
  assert_receive {:chunk, "Hello"}
  assert_receive {:chunk, " "}
  assert_receive {:chunk, "world"}
end
```

### Configuration Helpers

```elixir
# Set invoke response for a prompt
WishSdk.Api.Stub.set_response(slug, response)

# Set stream chunks with delay
WishSdk.Api.Stub.set_stream(slug, chunks, chunk_delay: 100)

# Clear all stub configurations
WishSdk.Api.Stub.clear()
```

### Using Stubs with Tasks

**Important:** Stub configuration uses the process dictionary, which is per-process!

When using `Task.async`, configure the stub **inside** the task:

```elixir
def handle_event("invoke", _params, socket) do
  liveview_pid = self()
  
  Task.async(fn ->
    # Configure stub INSIDE the task
    WishSdk.Api.Stub.set_response("my-prompt", "Mocked response")
    
    case WishSdk.invoke("my-prompt") do
      {:ok, response} -> send(liveview_pid, {:done, response})
      {:error, error} -> send(liveview_pid, {:error, error})
    end
  end)
  
  {:noreply, socket}
end
```

### Global Configuration

You can also configure default responses in your config:

```elixir
# config/test.exs
config :wish_sdk, :stub_responses, %{
  "default-prompt" => "Default response",
  "medical-summary" => "**Medical Summary**\n\nDefault medical data"
}

config :wish_sdk, :stub_streams, %{
  "stream-prompt" => {["Chunk ", "1", ", ", "Chunk ", "2"], 100}
}
```

### Benefits of Stub Pattern

- ✅ **No mocking libraries needed** - Knigge handles delegation
- ✅ **Environment-based** - Automatic based on `MIX_ENV`
- ✅ **Compile-time safe** - Behavior ensures all callbacks implemented
- ✅ **Same API** - Stub has identical interface to real client
- ✅ **Configurable** - Per-test or global configuration


## API Reference

### Core Functions

#### `WishSdk.invoke/2`

Invoke a BetterPrompt and get the complete response.

**Options:**
- `:context_variables` - Map of required context variables
- `:user_prompt` - User prompt text (if prompt is not frozen)
- `:api_url` - Override configured API URL
- `:timeout` - Request timeout in ms (default: 30000)

#### `WishSdk.stream/2`

Stream a BetterPrompt response with real-time chunks.

**Options:**
- `:context_variables` - Map of required context variables
- `:user_prompt` - User prompt text (if prompt is not frozen)
- `:on_chunk` - Callback for each chunk: `fn chunk -> ... end`
- `:on_done` - Callback when complete: `fn full_response -> ... end`
- `:on_error` - Callback on error: `fn error -> ... end`
- `:on_connected` - Callback when connected: `fn -> ... end`
- `:api_url` - Override configured API URL

#### `WishSdk.fetch_schema/1`

Fetch schemas for all available prompts.

#### `WishSdk.fetch_prompt_schema/2`

Fetch schema for a specific prompt by slug.

### Mix Tasks

#### `mix wish.gen.prompts`

Generates type-safe Ecto modules for all published BetterPrompts.

**Options:**
- `--api-url` - Override API URL
- `--output-dir` - Output directory (default: `lib/prompts`)
- `--module-prefix` - Module prefix (default: `YourApp.Prompts`)

**Example:**
```bash
mix wish.gen.prompts --output-dir lib/my_app/prompts --module-prefix MyApp.Prompts
```

## Components

### `<.wish_response />`

The main component for displaying AI responses with automatic state management.

**Attributes:**
- `content` - Response content (default: "")
- `status` - Status atom: `:idle`, `:connecting`, `:connected`, `:streaming`, `:done`, `:error`
- `show_status` - Show status indicator above response (default: false)
- `format` - Content format: "text", "markdown" (default), "html"
- `loading` - Show loading spinner (overridden by status if set)
- `streaming` - Show streaming cursor (default: true)
- `error` - Error message to display
- `loading_size` - Spinner size: "small", "medium" (default), "large"
- `empty_message` - Message when content is empty (default: "No content yet")
- `auto_scroll` - Auto-scroll during updates (default: true)
- `container_class` - Container CSS classes (default: "max-h-96 overflow-y-auto")

**Examples:**
```heex
# Simple usage with status atom
<.wish_response content={@response} status={@status} show_status={true} />

# With custom empty message
<.wish_response
  content={@response}
  status={@status}
  empty_message="Click 'Start' to begin"
/>

# Plain text format
<.wish_response content={@response} format="text" />
```

### `<.wish_status />`

Show connection and streaming status indicator.

**Attributes:**
- `status` - Current status: `:idle`, `:connecting`, `:connected`, `:streaming`, `:done`, `:error`
- `message` - Optional custom status message
- `class` - Additional CSS classes

**Example:**
```heex
<.wish_status status={@status} />
<.wish_status status={:streaming} message="Generating response..." />
```

## Development & Showcase

This repository includes `wish_sdk_development`, a Phoenix application that showcases all SDK features with interactive examples and documentation.

To run the showcase:

```bash
cd wish_sdk_development
mix deps.get
mix ecto.setup
iex -S mix phx.server
```

Visit http://localhost:4000

## Error Handling

The SDK provides consistent error handling:

```elixir
case WishSdk.invoke("my-prompt", context_variables: %{}) do
  {:ok, response} -> 
    IO.puts("Success: #{response}")
    
  {:error, %{status: 404, message: msg}} -> 
    IO.puts("Prompt not found: #{msg}")
    
  {:error, %{status: 400, message: msg}} -> 
    IO.puts("Bad request: #{msg}")
    
  {:error, %{status: :connection_error, message: msg}} -> 
    IO.puts("Connection failed: #{msg}")
end
```

## Examples

Check out the `wish_sdk_development/` directory for comprehensive examples including:

- Basic invocation patterns
- Streaming with different callbacks
- LiveView integration examples
- Error handling patterns
- Generated module usage
- Context variable validation

## Architecture

```
┌─────────────────┐
│   Your App      │
└────────┬────────┘
         │
         ├─────────────────┐
         │                 │
┌────────▼─────────┐  ┌───▼──────────────┐
│  WishSdk.invoke  │  │  WishSdk.stream  │
└────────┬─────────┘  └───┬──────────────┘
         │                 │
┌────────▼─────────────────▼────────┐
│      WishSdk.Client               │
│  (HTTP + SSE handling)            │
└────────┬──────────────────────────┘
         │
┌────────▼──────────┐
│   Wish API        │
│  /api/better-     │
│   prompt/:slug/   │
│   invoke|stream   │
└───────────────────┘
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT
## Links

- [Wish Documentation](https://github.com/yourusername/wish)
- [BetterPrompt Concept](https://github.com/yourusername/wish)
- [API Documentation](https://hexdocs.pm/wish_sdk)
