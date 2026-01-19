defmodule WishSdk.Api.Stub do
  @moduledoc """
  Test stub implementation for WishSdk.Api.

  Provides mock responses for testing without requiring a real API connection.
  Has the **same API** as `WishSdk.Api.Client` - no special parameters needed!

  ## Configuration

  Enable stub in config:

      config :wish_sdk, WishSdk.Api, WishSdk.Api.Stub

  ## Configuring Stub Responses

  ### Per-Test Configuration

      setup do
        # Set response for specific prompt
        WishSdk.Api.Stub.set_response("my-prompt", "Custom response")

        # Or set streaming chunks
        WishSdk.Api.Stub.set_stream("my-prompt", ["Hello", " ", "world"])

        :ok
      end

      test "uses configured response" do
        {:ok, response} = WishSdk.invoke("my-prompt")
        assert response == "Custom response"
      end

  ### Global Configuration (config/test.exs)

      config :wish_sdk, :stub_responses, %{
        "test-prompt" => "Default test response",
        "medical-summary" => "**Medical Summary**\\n\\nDefault medical data"
      }

  ## Default Behavior

  Without configuration, returns sensible default responses for any prompt.
  """

  @behaviour WishSdk.Api

  @default_response """
  **Mock Response**

  This is a stub response. Configure specific responses using `WishSdk.Api.Stub.set_response/2`.
  """

  @default_chunks [
    "**Streaming ",
    "Response**\n\n",
    "This is ",
    "a stub ",
    "stream."
  ]

  ## Public API for configuring stub responses

  @doc """
  Set the response for a specific prompt slug (for invoke).

  ## Example

      WishSdk.Api.Stub.set_response("my-prompt", "Custom response")
  """
  def set_response(slug, response) when is_binary(slug) and is_binary(response) do
    Process.put({__MODULE__, :response, slug}, response)
  end

  @doc """
  Set the stream chunks for a specific prompt slug (for stream).

  ## Example

      WishSdk.Api.Stub.set_stream("my-prompt", ["Hello", " ", "world"])
      WishSdk.Api.Stub.set_stream("my-prompt", ["Hello"], chunk_delay: 50)
  """
  def set_stream(slug, chunks, opts \\ []) when is_binary(slug) and is_list(chunks) do
    chunk_delay = Keyword.get(opts, :chunk_delay, 100)
    Process.put({__MODULE__, :stream, slug}, {chunks, chunk_delay})
  end

  @doc """
  Clear all stub configurations for the current process.
  """
  def clear() do
    Process.get_keys()
    |> Enum.filter(&match?({__MODULE__, _, _}, &1))
    |> Enum.each(&Process.delete/1)
  end

  ## WishSdk.Api callbacks

  @impl WishSdk.Api
  def invoke(prompt_or_slug, opts \\ []) do
    slug = extract_slug(prompt_or_slug)

    response =
      get_configured_response(slug) ||
        get_app_env_response(slug) ||
        @default_response

    # Optional delay for testing
    if delay = Keyword.get(opts, :__stub_delay) do
      Process.sleep(delay)
    end

    {:ok, response}
  end

  @impl WishSdk.Api
  def stream(prompt_or_slug, opts \\ []) do
    slug = extract_slug(prompt_or_slug)

    {chunks, chunk_delay} =
      get_configured_stream(slug) ||
        get_app_env_stream(slug) ||
        {@default_chunks, 100}

    on_chunk = Keyword.get(opts, :on_chunk)
    on_done = Keyword.get(opts, :on_done)
    on_connected = Keyword.get(opts, :on_connected)

    task =
      Task.async(fn ->
        if on_connected, do: on_connected.()

        full_response = stream_chunks(chunks, chunk_delay, on_chunk)

        if on_done, do: on_done.(full_response)
        {:ok, full_response}
      end)

    {:ok, task}
  end

  @impl WishSdk.Api
  def fetch_schema(_opts \\ []) do
    configured_schema = Application.get_env(:wish_sdk, :stub_schema)

    {:ok,
     configured_schema ||
       [
         %{
           "slug" => "medical-summary",
           "name" => "Medical Summary",
           "description" => "Generate comprehensive medical case summaries",
           "required_context_variables" => ["case_id"],
           "optional_context_variables" => ["document_id"]
         },
         %{
           "slug" => "test-prompt",
           "name" => "Test Prompt",
           "description" => "A test prompt for development",
           "required_context_variables" => [],
           "optional_context_variables" => ["optional_var"]
         }
       ]}
  end

  @impl WishSdk.Api
  def fetch_prompt_schema(slug, _opts \\ []) do
    case fetch_schema() do
      {:ok, schemas} ->
        case Enum.find(schemas, fn s -> s["slug"] == slug end) do
          nil -> {:error, %{status: 404, message: "Prompt '#{slug}' not found"}}
          schema -> {:ok, schema}
        end

      error ->
        error
    end
  end

  ## Private helpers

  defp extract_slug(%_{__wish_prompt__: slug}), do: slug
  defp extract_slug(%{__wish_prompt__: slug}), do: slug
  defp extract_slug(slug) when is_binary(slug), do: slug

  defp get_configured_response(slug) do
    Process.get({__MODULE__, :response, slug})
  end

  defp get_configured_stream(slug) do
    Process.get({__MODULE__, :stream, slug})
  end

  defp get_app_env_response(slug) do
    Application.get_env(:wish_sdk, :stub_responses, %{})
    |> Map.get(slug)
  end

  defp get_app_env_stream(slug) do
    case Application.get_env(:wish_sdk, :stub_streams, %{}) |> Map.get(slug) do
      nil -> nil
      {chunks, delay} -> {chunks, delay}
      chunks when is_list(chunks) -> {chunks, 100}
    end
  end

  defp stream_chunks(chunks, delay, on_chunk, acc \\ "") do
    case chunks do
      [] ->
        acc

      [chunk | rest] ->
        if on_chunk, do: on_chunk.(chunk)
        if delay > 0, do: Process.sleep(delay)
        stream_chunks(rest, delay, on_chunk, acc <> chunk)
    end
  end
end
