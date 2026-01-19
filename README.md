# WishSdk

Elixir SDK for integrating BetterPrompts from Wish API into your applications.

## Installation

Add to `mix.exs`:

```elixir
def deps do
  [
    {:wish_sdk, "~> 0.1.0"}
  ]
end
```

## Configuration

In `config/config.exs`:

```elixir
config :wish_sdk,
  api_url: "https://your-wish-instance.com",
  api_token: "your-platform-token"
```

The token is sent as `x-platform-internal-call-token` header.

Or use environment variables:

```bash
export WISH_API_URL=https://your-wish-instance.com
export WISH_API_TOKEN=your-platform-token
```

## Usage

### Generate Type-Safe Modules

Discover available prompts:

```bash
mix wish.list.prompts
```

Generate the prompt you need:

```bash
# Generate a single prompt (recommended)
mix wish.gen.prompt medical-summary
# => creates lib/wish_prompts/medical_summary.ex
```

This creates an Ecto schema with `@enforce_keys` for compile-time safety:

```elixir
# lib/wish_prompts/medical_summary.ex
defmodule MyApp.Prompts.MedicalSummary do
  use Ecto.Schema
  
  @enforce_keys [:case_id, :document_id]
  
  embedded_schema do
    field :case_id, :string
    field :document_id, :string
  end
  
  def invoke(params, opts \\ [])
  def stream(params, opts \\ [])
end
```

### Invoke

```elixir
alias MyApp.Prompts.MedicalSummary

# Using struct (compile-time safe)
%MedicalSummary{case_id: "123", document_id: "456"}
|> WishSdk.invoke()

# Using helper
MedicalSummary.invoke(case_id: "123", document_id: "456")

# Using string slug (no compile-time safety)
WishSdk.invoke("medical-summary",
  context_variables: %{case_id: "123", document_id: "456"}
)
```

### Stream

```elixir
%MedicalSummary{case_id: "123", document_id: "456"}
|> WishSdk.stream(
  on_chunk: fn chunk -> IO.write(chunk) end,
  on_done: fn _ -> IO.puts("\n✓ Complete") end,
  on_error: fn error -> IO.puts("Error: #{inspect(error)}") end
)
```

## LiveView Integration

### Setup

In `lib/my_app_web.ex`:

```elixir
defp html_helpers do
  quote do
    use WishSdk.Components
  end
end
```

### Example

```elixir
defmodule MyAppWeb.PromptLive do
  use MyAppWeb, :live_view
  alias MyApp.Prompts.MedicalSummary

  def mount(_params, _session, socket) do
    {:ok, assign(socket, response: "", status: :idle)}
  end

  def handle_event("generate", %{"case_id" => case_id, "doc_id" => doc_id}, socket) do
    socket = assign(socket, status: :streaming, response: "")
    
    {:ok, _} = %MedicalSummary{case_id: case_id, document_id: doc_id}
    |> WishSdk.stream(
      on_chunk: fn chunk -> send(self(), {:chunk, chunk}) end,
      on_done: fn _ -> send(self(), :done) end
    )
    
    {:noreply, socket}
  end

  def handle_info({:chunk, chunk}, socket) do
    {:noreply, update(socket, :response, &(&1 <> chunk))}
  end

  def handle_info(:done, socket) do
    {:noreply, assign(socket, :status, :done)}
  end

  def render(assigns) do
    ~H"""
    <.wish_prompt response={@response} status={@status} />
    """
  end
end
```

## API Reference

### `WishSdk.invoke/2`

```elixir
WishSdk.invoke(prompt_or_slug, opts \\ [])
```

**Arguments:**
- `prompt_or_slug` - Prompt struct (e.g., `%MedicalSummary{}`) or slug string
- `opts` - Options keyword list

**Options:**
- `:context_variables` - Map of context variables (when using slug)
- `:user_prompt` - User prompt text
- `:api_url` - Override API URL
- `:api_token` - Override API token
- `:timeout` - Timeout in ms (default: 30000)

**Returns:** `{:ok, response}` or `{:error, reason}`

### `WishSdk.stream/2`

```elixir
WishSdk.stream(prompt_or_slug, opts \\ [])
```

**Options:**
- `:context_variables` - Map of context variables (when using slug)
- `:user_prompt` - User prompt text
- `:on_chunk` - Callback for each chunk: `fn chunk -> ... end`
- `:on_done` - Callback when complete: `fn full_response -> ... end`
- `:on_error` - Callback on error: `fn error -> ... end`
- `:on_connected` - Callback when connected: `fn -> ... end`
- `:api_url` - Override API URL
- `:api_token` - Override API token

**Returns:** `{:ok, task}` or `{:error, reason}`

### `WishSdk.fetch_schema/1`

Fetch schemas for all available prompts.

### `WishSdk.fetch_prompt_schema/2`

Fetch schema for a specific prompt by slug.

## Mix Tasks

### `mix wish.list.prompts`

List all available prompts from your Wish API:

```bash
mix wish.list.prompts
```

### `mix wish.gen.prompt`

Generate a type-safe module for a single prompt:

```bash
mix wish.gen.prompt SLUG
```

**Options:**
- `--api-url` - Override API URL
- `--output-dir` - Output directory (default: `lib/wish_prompts`)
- `--module-prefix` - Module prefix (default: `YourApp.Prompts`)

**Example:**
```bash
mix wish.gen.prompt medical-summary
```

### `mix wish.gen.prompts` (Batch)

Generate multiple prompts at once (output to `lib/wish_prompts`):

```bash
# Generate specific prompts
mix wish.gen.prompts --only medical-summary,case-analyzer

# Generate all except some
mix wish.gen.prompts --except test-prompt,debug-helper
```

## Components

### `<.wish_response />`

```heex
# Markdown (default)
<.wish_response content={@response} />

# With streaming cursor and auto-scroll
<.wish_response content={@response} streaming={true} auto_scroll={true} />

# Plain text
<.wish_response content={@response} format="text" />

# Loading state
<.wish_response content="" loading={true} />

# Loading state with custom size
<.wish_response content="" loading={true} size="large" />
```

Display formatted responses with markdown support (default).

**Attributes:**
- `content` - Response content
- `format` - `"markdown"` (default), `"text"`, or `"html"`
- `streaming` - Show streaming cursor animation
- `loading` - Show loading spinner
- `size` - Spinner size: `"small"`, `"medium"` (default), or `"large"`
- `auto_scroll` - Auto-scroll to bottom during updates (requires JavaScript hooks)
- `class` - Additional CSS classes

### `<.wish_prompt />`

```heex
<.wish_prompt response={@response} status={@status} />

# With auto-scroll and markdown (default)
<.wish_prompt response={@response} status={@status} auto_scroll={true} />

# Plain text format
<.wish_prompt response={@response} status={@status} format="text" />
```

Combined prompt display with response and status. Uses `wish_response` internally with markdown rendering by default.

**Attributes:**
- `response` - Response content
- `status` - Current status (`:idle`, `:streaming`, `:done`, `:error`)
- `format` - Response format: `"markdown"` (default), `"text"`, or `"html"`
- `auto_scroll` - Auto-scroll to bottom during updates (default: `false`)
- `show_status` - Show status indicator (default: `true`)
- `class` - Additional CSS classes

### `<.wish_status />`

```heex
<.wish_status status={@status} message={@message} />
```

Shows connection/streaming status indicator.

**Attributes:**
- `status` - `:idle`, `:connecting`, `:streaming`, `:done`, `:error`
- `message` - Optional status message

## Testing with Stubs

WishSdk uses **Knigge** for behavior delegation, following the same pattern as your Wish project.

The stub has the **exact same API** as the real client - no special parameters needed!

### Configuration

Configure the stub implementation in your test config:

```elixir
# config/test.exs
config :wish_sdk, WishSdk.Api, WishSdk.Api.Stub
```

Once configured, **all** `WishSdk` calls automatically use the stub!

### Configuring Stub Responses

```elixir
setup do
  # Set response for specific prompt slug
  WishSdk.Api.Stub.set_response("test-prompt", "Mocked response")
  
  # Set streaming chunks
  WishSdk.Api.Stub.set_stream("stream-prompt", ["Hello", " ", "world"])
  
  :ok
end

test "uses configured response" do
  {:ok, response} = WishSdk.invoke("test-prompt")
  assert response == "Mocked response"
end

test "uses configured stream" do
  {:ok, _task} = WishSdk.stream("stream-prompt",
    on_chunk: fn chunk -> send(self(), {:chunk, chunk}) end
  )
  
  assert_receive {:chunk, "Hello"}
  assert_receive {:chunk, " "}
  assert_receive {:chunk, "world"}
end
```

### Global Configuration

You can also configure default responses in config:

```elixir
# config/test.exs
config :wish_sdk, :stub_responses, %{
  "default-prompt" => "Default response",
  "medical-summary" => "**Medical Summary**\n\nDefault data"
}

config :wish_sdk, :stub_streams, %{
  "stream-prompt" => {["Chunk ", "1", ", ", "Chunk ", "2"], 100}
}
```

### Configuration Helpers

```elixir
# Configure per-test
WishSdk.Api.Stub.set_response(slug, response)
WishSdk.Api.Stub.set_stream(slug, chunks, chunk_delay: 100)

# Clear all configurations
WishSdk.Api.Stub.clear()
```

### Using Stubs with Tasks

**Important:** Stub configuration is stored in the **process dictionary**, which is per-process!

When using `Task.async`, configure the stub **inside** the task:

```elixir
def handle_event("invoke", _params, socket) do
  liveview_pid = self()
  
  Task.async(fn ->
    # Configure stub INSIDE the task
    WishSdk.Api.Stub.set_response("my-prompt", "Mocked response")
    
    # Now this will use the stub
    case WishSdk.invoke("my-prompt") do
      {:ok, response} -> send(liveview_pid, {:done, response})
      {:error, error} -> send(liveview_pid, {:error, error})
    end
  end)
  
  {:noreply, socket}
end
```

### Using Stubs in Production Demos

For showcase pages that should always use stubs (even in production), call the stub directly:

```elixir
defmodule MyAppWeb.DemoLive do
  @moduledoc """
  Demo page that uses stubs to work without a real API.
  """
  
  def handle_event("demo", _params, socket) do
    liveview_pid = self()
    
    Task.async(fn ->
      # Configure stub inside task
      WishSdk.Api.Stub.set_response("demo", "Mock response")
      
      # Call stub directly (not WishSdk)
      case WishSdk.Api.Stub.invoke("demo") do
        {:ok, response} -> send(liveview_pid, {:done, response})
      end
    end)
    
    {:noreply, socket}
  end
end
```

This keeps your demo working everywhere, while other pages use the real `WishSdk.invoke/2`.

### Predefined Presets

```elixir
# Use presets for common scenarios
config = WishSdk.Api.Stub.preset(:progressive_stream)
WishSdk.Api.Stub.stream(prompt, config)

# Available presets:
# - :quick_response (invoke)
# - :slow_response (invoke)
# - :medical_summary (stream)
# - :progressive_stream (stream)
# - :fast_stream (stream)
# - :error_timeout (error)

# Override preset values
config = WishSdk.Api.Stub.preset(:quick_response, 
  content: "Custom content",
  delay: 500
)
```

### LiveView Testing

```elixir
# In test_helper.exs
config :wish_sdk, WishSdk.Api, WishSdk.Api.Stub

test "streaming updates response", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/stream")
  
  # Trigger streaming (uses stub automatically)
  view
  |> element("button", "Start Stream")
  |> render_click()
  
  # Verify UI updates
  assert render(view) =~ "streaming"
end
```

### Architecture

Following the Knigge pattern from your Wish project:

- **`WishSdk.Api`** - Behavior module (uses Knigge)
- **`WishSdk.Api.Client`** - Real HTTP client implementation (default)
- **`WishSdk.Api.Stub`** - Test stub implementation

All calls through `WishSdk.invoke/2` and `WishSdk.stream/2` delegate to `WishSdk.Api`, which routes to the configured implementation.

## Error Handling

```elixir
case WishSdk.invoke(prompt) do
  {:ok, response} -> 
    {:ok, response}
    
  {:error, %{status: 404}} -> 
    {:error, :not_found}
    
  {:error, %{status: 400, message: msg}} -> 
    {:error, msg}
    
  {:error, %{status: :connection_error}} -> 
    {:error, :connection_failed}
end
```

## Common Patterns

### Batch Processing

```elixir
["123", "456", "789"]
|> Task.async_stream(fn id ->
  %MyPrompt{id: id} |> WishSdk.invoke()
end, max_concurrency: 5)
|> Enum.to_list()
```

### With Custom Validation

```elixir
# Add custom validation to generated module's changeset
def changeset(struct, params) do
  struct
  |> cast(params, [:case_id, :document_id])
  |> validate_required([:case_id, :document_id])
  |> validate_format(:case_id, ~r/^CASE-\d+$/)
end

# Then use .new() for validation
case MyPrompt.new(params) do
  {:ok, prompt} -> WishSdk.invoke(prompt)
  {:error, changeset} -> {:error, format_errors(changeset)}
end
```

### Progress Tracking

```elixir
chars = 0

WishSdk.stream(prompt,
  on_chunk: fn chunk ->
    chars = chars + String.length(chunk)
    IO.write("#{chars} chars received\r")
  end,
  on_done: fn _ -> IO.puts("\nComplete!") end
)
```

## Development

Run the showcase application:

```bash
cd wish_sdk_development
mix deps.get
iex -S mix phx.server
```

Visit http://localhost:4001

## License

MIT
