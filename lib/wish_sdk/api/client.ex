defmodule WishSdk.Api.Client do
  @moduledoc """
  Real HTTP client implementation for the Wish API.

  Handles all communication with the Wish API including invoke, stream, and schema endpoints.
  """

  @behaviour WishSdk.Api

  require Logger

  @default_timeout 30_000

  @doc """
  Invoke a BetterPrompt and wait for the complete response.
  """
  @impl WishSdk.Api
  def invoke(slug, opts \\ []) do
    api_url = get_api_url(opts)
    context_variables = Keyword.get(opts, :context_variables, %{})
    user_prompt = Keyword.get(opts, :user_prompt)
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    url = build_url(api_url, "/api/better-prompt/#{slug}/invoke")

    body =
      %{context_variables: context_variables}
      |> maybe_add_user_prompt(user_prompt)
      |> Jason.encode!()

    headers = build_headers(opts, [{"content-type", "application/json"}])

    case Req.post(url,
           body: body,
           headers: headers,
           receive_timeout: timeout
         ) do
      {:ok, %{status: 200, body: response}} ->
        {:ok, response["response"]}

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, message: parse_error_message(body)}}

      {:error, reason} ->
        {:error, %{status: :connection_error, message: inspect(reason)}}
    end
  end

  @doc """
  Stream a BetterPrompt response with real-time chunks via Server-Sent Events.
  """
  @impl WishSdk.Api
  def stream(slug, opts \\ []) do
    api_url = get_api_url(opts)
    context_variables = Keyword.get(opts, :context_variables, %{})
    user_prompt = Keyword.get(opts, :user_prompt)

    on_chunk = Keyword.get(opts, :on_chunk, fn _ -> :ok end)
    on_done = Keyword.get(opts, :on_done, fn _ -> :ok end)
    on_error = Keyword.get(opts, :on_error, fn _ -> :ok end)
    on_connected = Keyword.get(opts, :on_connected, fn -> :ok end)

    url = build_url(api_url, "/api/better-prompt/#{slug}/stream")

    body =
      %{context_variables: context_variables}
      |> maybe_add_user_prompt(user_prompt)
      |> Jason.encode!()

    headers =
      build_headers(opts, [
        {"content-type", "application/json"},
        {"accept", "text/event-stream"}
      ])

    task =
      Task.async(fn ->
        case Req.post(url,
               body: body,
               headers: headers,
               into: fn {:data, data}, {req, resp} ->
                 parse_sse_chunk(data, on_chunk, on_done, on_error, on_connected)
                 {:cont, {req, resp}}
               end
             ) do
          {:ok, _} ->
            :ok

          {:error, reason} ->
            on_error.(%{status: :connection_error, message: inspect(reason)})
            {:error, reason}
        end
      end)

    {:ok, task}
  end

  @doc """
  Fetch schemas for all available prompts.
  """
  @impl WishSdk.Api
  def fetch_schema(opts \\ []) do
    api_url = get_api_url(opts)
    url = build_url(api_url, "/api/prompts/schema")
    headers = build_headers(opts, [])

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: response}} ->
        {:ok, response}

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, message: parse_error_message(body)}}

      {:error, reason} ->
        {:error, %{status: :connection_error, message: inspect(reason)}}
    end
  end

  @doc """
  Fetch schema for a specific prompt by slug.
  """
  @impl WishSdk.Api
  def fetch_prompt_schema(slug, opts \\ []) do
    case fetch_schema(opts) do
      {:ok, %{"prompts" => prompts}} ->
        case Enum.find(prompts, fn p -> p["slug"] == slug end) do
          nil -> {:error, %{status: 404, message: "Prompt not found"}}
          prompt -> {:ok, prompt}
        end

      error ->
        error
    end
  end

  # Private functions

  defp get_api_url(opts) do
    Keyword.get(opts, :api_url) ||
      Application.get_env(:wish_sdk, :api_url) ||
      raise """
      API URL not configured. Please set it in your config:

          config :wish_sdk,
            api_url: "https://your-wish-instance.com"

      Or pass it as an option:

          WishSdk.invoke("slug", api_url: "https://your-wish-instance.com")
      """
  end

  defp get_api_token(opts) do
    Keyword.get(opts, :api_token) ||
      Application.get_env(:wish_sdk, :api_token) ||
      System.get_env("WISH_API_TOKEN")
  end

  defp build_headers(opts, base_headers) do
    case get_api_token(opts) do
      nil -> base_headers
      token -> [{"x-platform-internal-call-token", token} | base_headers]
    end
  end

  defp build_url(base_url, path) do
    base_url
    |> String.trim_trailing("/")
    |> Kernel.<>(path)
  end

  defp maybe_add_user_prompt(body, nil), do: body
  defp maybe_add_user_prompt(body, user_prompt), do: Map.put(body, :user_prompt, user_prompt)

  defp parse_error_message(body) when is_binary(body), do: body
  defp parse_error_message(%{"error" => error}), do: error
  defp parse_error_message(%{"message" => message}), do: message
  defp parse_error_message(body), do: inspect(body)

  defp parse_sse_chunk(data, on_chunk, on_done, on_error, on_connected) do
    String.split(data, "\n\n", trim: true)
    |> Enum.each(fn event_block ->
      lines = String.split(event_block, "\n", trim: true)
      event_type = extract_event_type(lines)
      event_data = extract_event_data(lines)

      case event_type do
        "connected" ->
          on_connected.()

        "chunk" ->
          on_chunk.(event_data)

        "done" ->
          case Jason.decode(event_data) do
            {:ok, %{"response" => response}} -> on_done.(response)
            _ -> on_done.(event_data)
          end

        "error" ->
          case Jason.decode(event_data) do
            {:ok, error} -> on_error.(error)
            _ -> on_error.(%{message: event_data})
          end

        _ ->
          :ignore
      end
    end)
  rescue
    e ->
      Logger.error("Error parsing SSE chunk: #{inspect(e)}")
      :error
  end

  defp extract_event_type(lines) do
    Enum.find_value(lines, "message", fn line ->
      case String.split(line, ":", parts: 2) do
        ["event", type] -> String.trim(type)
        _ -> nil
      end
    end)
  end

  defp extract_event_data(lines) do
    # SSE spec: multiple data: lines should be concatenated with newlines
    data_lines =
      for line <- lines,
          ["data", data] <- [String.split(line, ":", parts: 2)] do
        # SSE spec: only remove the first space after the colon (if present)
        # This preserves any leading spaces that are part of the actual content
        case data do
          " " <> rest -> rest
          other -> other
        end
      end

    case data_lines do
      [] -> ""
      lines -> Enum.join(lines, "\n")
    end
  end
end
