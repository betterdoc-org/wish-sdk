defmodule WishSdk do
  @moduledoc """
  **Pure Elixir SDK** for integrating BetterPrompt AI capabilities.

  This SDK provides a simple, pure Elixir interface for invoking AI prompts via the Wish API.

  ## Features

  - 🚀 Simple `invoke/2` and `stream/2` functions
  - 🔒 Pure Elixir
  - 📡 Real-time streaming via Server-Sent Events
  - 🎨 Optional LiveView components
  - 🔧 Mix task for generating type-safe modules

  ## Quick Start

  ### Configuration

  Configure the Wish API URL and platform token in your config.exs:

      config :wish_sdk,
        api_url: "https://your-wish-instance.com",
        api_token: "your-platform-token"

  ### Invoke API

      # Simple invocation
      {:ok, response} = WishSdk.invoke("medical-summary",
        context_variables: %{
          case_id: "123",
          document_id: "456"
        }
      )

      # With user prompt (if not frozen)
      {:ok, response} = WishSdk.invoke("prompt-slug",
        user_prompt: "What are the symptoms?",
        context_variables: %{case_id: "123"}
      )

  ### Stream API

  Real-time streaming with callbacks - all server-side:

      WishSdk.stream("medical-summary",
        context_variables: %{case_id: "123"},
        on_chunk: fn chunk -> IO.write(chunk) end,
        on_done: fn response -> IO.puts("\\nDone!") end,
        on_error: fn error -> IO.puts("Error: \#{inspect(error)}") end
      )

  ### LiveView Integration

  #### High-Level (Zero Boilerplate) ⭐ Recommended

  Use the self-managing `LivePrompt` component for the simplest integration:

      # Just pass the slug and context - that's it!
      <.live_component
        module={WishSdk.Components.LivePrompt}
        id="my-prompt"
        slug="medical-summary"
        context_variables={%{case_id: "123"}}
        auto_start={true}
      />

  The component handles all state, callbacks, and message handling internally.

  #### Low-Level (Manual Control)

  For complex scenarios, use the low-level API with manual state management:

      def handle_event("invoke", _params, socket) do
        socket = assign(socket, response: "", status: :streaming)

        {:ok, _task} = WishSdk.stream("medical-summary",
          context_variables: %{case_id: "123"},
          on_chunk: fn chunk -> send(self(), {:chunk, chunk}) end,
          on_done: fn _ -> send(self(), :done) end
        )

        {:noreply, socket}
      end

      def handle_info({:chunk, chunk}, socket) do
        {:noreply, update(socket, :response, &(&1 <> chunk))}
      end

      # In your template
      <.wish_response content={@response} status={@status} show_status={true} />

  ## Components

  To use the optional display components, import them:

      use WishSdk.Components

  Available components:
  - `wish_response` - Display responses with status, streaming, and error handling
  - `wish_status` - Show connection status indicators
  - `WishSdk.Components.LivePrompt` - Self-managing LiveComponent (zero boilerplate!)

  ### Optional JavaScript Hooks

  For UI enhancements like auto-scrolling (optional):

      # Copy hooks file
      cp deps/wish_sdk/priv/static/wish_sdk_hooks.js assets/vendor/

      # Import in assets/js/app.js
      import WishHooks from "../vendor/wish_sdk_hooks";
      let liveSocket = new LiveSocket("/live", Socket, {hooks: WishHooks})

  ## Type-Safe Modules

  Generate Ecto-based modules with compile-time safety:

      mix wish.gen.prompts

  Then use them with compile-time validation:

      # Compile-time error if fields are missing!
      %MyApp.Prompts.MedicalSummary{
        case_id: "123",
        document_id: "456"
      }
      |> WishSdk.invoke()

  ## Testing with Stubs

  WishSdk uses **Knigge** for behavior delegation, making testing easy without a real API:

      # config/test.exs
      config :wish_sdk, WishSdk.Api, WishSdk.Api.Stub

  In your tests:

      setup do
        WishSdk.Api.Stub.set_response("medical-summary", "Mocked response")
        WishSdk.Api.Stub.set_stream("patient-onboarding", ["Hello", " ", "world"])
        :ok
      end

      test "handles invoke" do
        {:ok, response} = WishSdk.invoke("medical-summary")
        assert response == "Mocked response"
      end

      test "handles streaming" do
        {:ok, _task} = WishSdk.stream("patient-onboarding",
          on_chunk: fn chunk -> send(self(), {:chunk, chunk}) end
        )
        assert_receive {:chunk, "Hello"}
      end

  Configuration helpers:

      WishSdk.Api.Stub.set_response(slug, response)
      WishSdk.Api.Stub.set_stream(slug, chunks, chunk_delay: 100)
      WishSdk.Api.Stub.clear()

  **Important:** Stub configuration is per-process. When using `Task.async`, configure
  the stub inside the task:

      Task.async(fn ->
        WishSdk.Api.Stub.set_response("prompt", "Response")
        WishSdk.invoke("prompt")
      end)
  """

  defmacro __using__(_) do
    quote do
      import WishSdk.Components.{
        Response,
        Status
      }
    end
  end

  @doc """
  Invoke a BetterPrompt and get the complete response.

  ## Options

    * `:context_variables` - Map of context variables required by the prompt
    * `:user_prompt` - User prompt text (if prompt is not frozen)
    * `:api_url` - Override the configured API URL
    * `:api_token` - Override the platform internal call token
    * `:timeout` - Request timeout in milliseconds (default: 30_000)

  ## Examples

      # Direct invocation
      {:ok, response} = WishSdk.invoke("medical-summary",
        context_variables: %{case_id: "123"}
      )
      #=> {:ok, "The patient presents with..."}

      # With generated module (struct - compile-time safe!)
      alias MyApp.Prompts.MedicalSummary

      %MedicalSummary{case_id: "123", document_id: "456"}
      |> WishSdk.invoke()
      #=> {:ok, "The patient presents with..."}

      # Or use the module's invoke directly
      MedicalSummary.invoke(case_id: "123", document_id: "456")
      #=> {:ok, "The patient presents with..."}
  """
  def invoke(slug_or_struct, opts \\ [])

  def invoke(%_module{} = struct, opts) do
    {slug, struct_opts} = WishSdk.Prompt.to_opts(struct)
    merged_opts = Keyword.merge(struct_opts, opts)
    WishSdk.Api.invoke(slug, merged_opts)
  end

  def invoke(slug, opts) when is_binary(slug) do
    WishSdk.Api.invoke(slug, opts)
  end

  @doc """
  Stream a BetterPrompt response with real-time chunks.

  ## Options

    * `:context_variables` - Map of context variables required by the prompt
    * `:user_prompt` - User prompt text (if prompt is not frozen)
    * `:on_chunk` - Callback function for each chunk of the response
    * `:on_done` - Callback function when streaming is complete
    * `:on_error` - Callback function if an error occurs
    * `:on_connected` - Callback function when connection is established
    * `:api_url` - Override the configured API URL
    * `:api_token` - Override the platform internal call token

  ## Examples

      # Direct streaming
      WishSdk.stream("medical-summary",
        context_variables: %{case_id: "123"},
        on_chunk: fn chunk -> IO.write(chunk) end,
        on_done: fn response -> IO.puts("\\nDone!") end
      )

      # With generated module (struct - compile-time safe!)
      alias MyApp.Prompts.MedicalSummary

      %MedicalSummary{case_id: "123", document_id: "456"}
      |> WishSdk.stream(
        on_chunk: fn chunk -> IO.write(chunk) end,
        on_done: fn _ -> IO.puts("\\nDone!") end
      )

      # Or use the module's stream directly
      MedicalSummary.stream([case_id: "123", document_id: "456"],
        on_chunk: fn chunk -> IO.write(chunk) end
      )
  """
  def stream(slug_or_struct, opts \\ [])

  def stream(%_module{} = struct, opts) do
    {slug, struct_opts} = WishSdk.Prompt.to_opts(struct)
    merged_opts = Keyword.merge(struct_opts, opts)
    WishSdk.Api.stream(slug, merged_opts)
  end

  def stream(slug, opts) when is_binary(slug) do
    WishSdk.Api.stream(slug, opts)
  end

  @doc """
  Fetch the schema for all available prompts.

  Returns information about published prompts including their required
  context variables, descriptions, and configuration.

  ## Options

    * `:api_url` - Override the configured API URL

  ## Examples

      {:ok, schema} = WishSdk.fetch_schema()
      #=> {:ok, %{prompts: [%{slug: "medical-summary", ...}]}}
  """
  def fetch_schema(opts \\ []) do
    WishSdk.Api.fetch_schema(opts)
  end

  @doc """
  Fetch the schema for a specific prompt by slug.

  ## Options

    * `:api_url` - Override the configured API URL

  ## Examples

      {:ok, prompt} = WishSdk.fetch_prompt_schema("medical-summary")
      #=> {:ok, %{slug: "medical-summary", required_context_variables: [...]}}
  """
  def fetch_prompt_schema(slug, opts \\ []) do
    WishSdk.Api.fetch_prompt_schema(slug, opts)
  end
end
