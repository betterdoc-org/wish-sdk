defmodule Mix.Tasks.Wish.Gen.Prompt do
  @moduledoc """
  Generates a type-safe Elixir module for a specific BetterPrompt from the Wish API.

  ## Usage

      mix wish.gen.prompt SLUG

  ## Examples

      # Generate module for medical-summary prompt
      mix wish.gen.prompt medical-summary

      # Generate with custom output directory
      mix wish.gen.prompt case-analyzer --output-dir lib/my_app/prompts

  ## Options

    * `--api-url` - Override the API URL (default: from config)
    * `--output-dir` - Output directory (default: lib/wish_prompts)
    * `--module-prefix` - Module prefix (default: YourApp.Prompts)

  ## What it does

  This task fetches the schema for a specific prompt and generates:

  1. An Ecto embedded schema with `@enforce_keys` for compile-time safety
  2. Helper functions for invoking and streaming
  3. Optional validation with `new/1` function

  The generated module will be placed in your project's lib directory,
  ready to be customized and version controlled.
  """

  use Mix.Task

  @shortdoc "Generates a type-safe module for a specific BetterPrompt"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, [slug | _], _} =
      OptionParser.parse(args,
        strict: [
          api_url: :string,
          output_dir: :string,
          module_prefix: :string
        ]
      )

    unless slug do
      Mix.raise("""
      Missing prompt slug argument.

      Usage: mix wish.gen.prompt SLUG

      Example:
        mix wish.gen.prompt medical-summary
      """)
    end

    api_url = opts[:api_url] || Application.get_env(:wish_sdk, :api_url)
    output_dir = opts[:output_dir] || "lib/wish_prompts"
    module_prefix = opts[:module_prefix] || infer_module_prefix()

    unless api_url do
      Mix.raise("""
      No API URL configured. Please either:
      1. Set it in config.exs: config :wish_sdk, api_url: "https://your-wish-instance.com"
      2. Pass it as an option: mix wish.gen.prompt #{slug} --api-url https://your-wish-instance.com
      """)
    end

    Mix.shell().info("Fetching prompt '#{slug}' from #{api_url}...")

    case WishSdk.fetch_prompt_schema(slug, api_url: api_url) do
      {:ok, prompt} ->
        File.mkdir_p!(output_dir)
        file_path = generate_prompt_module(prompt, output_dir, module_prefix)

        Mix.shell().info("""

        ✓ Generated module for '#{slug}' prompt

        File: #{file_path}
        Module: #{module_name(prompt, module_prefix)}

        You can now use it in your code:

            alias #{module_name(prompt, module_prefix)}

            %#{module_name(prompt, module_prefix) |> String.split(".") |> List.last()}{...}
            |> WishSdk.invoke()
        """)

      {:error, %{status: 404}} ->
        Mix.raise("""
        Prompt '#{slug}' not found.

        To see available prompts, run:
          mix wish.list.prompts
        """)

      {:error, error} ->
        Mix.raise("Failed to fetch prompt schema: #{inspect(error)}")
    end
  end

  defp infer_module_prefix do
    case Mix.Project.config()[:app] do
      nil ->
        "Prompts"

      app ->
        app
        |> to_string()
        |> Macro.camelize()
        |> then(&"#{&1}.Prompts")
    end
  end

  defp module_name(prompt, module_prefix) do
    module_suffix =
      prompt["slug"]
      |> String.replace("-", "_")
      |> Macro.camelize()

    "#{module_prefix}.#{module_suffix}"
  end

  defp generate_prompt_module(prompt, output_dir, module_prefix) do
    module_name = module_name(prompt, module_prefix)
    file_name = prompt["slug"] |> String.replace("-", "_")
    file_path = Path.join(output_dir, "#{file_name}.ex")

    required_vars = prompt["required_context_variables"] || []
    optional_vars = prompt["optional_context_variables"] || []
    all_vars = required_vars ++ optional_vars

    enforce_keys = Enum.map(required_vars, fn var -> ":#{var["name"]}" end)

    content = """
    defmodule #{module_name} do
      @moduledoc \"\"\"
      Auto-generated module for the '#{prompt["slug"]}' BetterPrompt.

      **Name:** #{prompt["name"]}
      **Description:** #{prompt["description"] || "No description available"}

      ## Required context variables

      #{format_variables(required_vars)}

      #{if length(optional_vars) > 0 do
      """
      ## Optional context variables

      #{format_variables(optional_vars)}
      """
    else
      ""
    end}

      ## Usage

          alias #{module_name}

          # Using struct (compile-time safe)
          %#{module_name |> String.split(".") |> List.last()}{#{format_example_fields(required_vars)}}
          |> WishSdk.invoke()

          # Using helper
          #{module_name |> String.split(".") |> List.last()}.invoke(#{format_example_params(required_vars)})

      ## Streaming

          %#{module_name |> String.split(".") |> List.last()}{#{format_example_fields(required_vars)}}
          |> WishSdk.stream(
            on_chunk: fn chunk -> IO.write(chunk) end,
            on_done: fn _ -> IO.puts("\\nComplete!") end
          )
      \"\"\"

      @behaviour WishSdk.Prompt

      use Ecto.Schema
      import Ecto.Changeset

      @enforce_keys [#{Enum.join(enforce_keys, ", ")}]

      @primary_key false
      embedded_schema do
    #{Enum.map_join(all_vars, "\n", fn var -> "    field :#{var["name"]}, :string" end)}
      end

      @impl WishSdk.Prompt
      def slug, do: "#{prompt["slug"]}"

      @doc \"\"\"
      Creates and validates a #{module_name |> String.split(".") |> List.last()} struct.

      Only needed if you add custom validation rules to the changeset.
      For basic usage, just use the struct directly: `%#{module_name |> String.split(".") |> List.last()}{...}`
      \"\"\"
      @impl WishSdk.Prompt
      def new(params) do
        changeset(params)
        |> apply_action(:insert)
      end

      @doc \"\"\"
      Validates parameters for this prompt.

      You can add custom validation rules here:

          def changeset(params) do
            %__MODULE__{}
            |> cast(params, #{inspect(Enum.map(all_vars, &String.to_atom(&1["name"])))})
            |> validate_required(#{inspect(Enum.map(required_vars, &String.to_atom(&1["name"])))})
            |> validate_format(:case_id, ~r/^CASE-\\d+$/)  # ← Add your rules
          end
      \"\"\"
      def changeset(params) when is_map(params) or is_list(params) do
        data = %{}
        types = #{inspect(Enum.into(all_vars, %{}, fn var -> {String.to_atom(var["name"]), :string} end))}

        {data, types}
        |> cast(params, #{inspect(Enum.map(all_vars, &String.to_atom(&1["name"])))})
        |> validate_required(#{inspect(Enum.map(required_vars, &String.to_atom(&1["name"])))})
      end

      @doc \"\"\"
      Invokes the prompt with the given parameters.

      ## Examples

          # With struct
          %#{module_name |> String.split(".") |> List.last()}{#{format_example_fields(required_vars)}}
          |> #{module_name |> String.split(".") |> List.last()}.invoke()

          # With params
          #{module_name |> String.split(".") |> List.last()}.invoke(#{format_example_params(required_vars)})
      \"\"\"
      @impl WishSdk.Prompt
      def invoke(params, opts \\\\ []) do
        context_variables = to_context_variables(params)
        WishSdk.invoke("#{prompt["slug"]}", Keyword.merge([context_variables: context_variables], opts))
      end

      @doc \"\"\"
      Streams the prompt response with the given parameters.

      ## Examples

          #{module_name |> String.split(".") |> List.last()}.stream(#{format_example_params(required_vars)},
            on_chunk: fn chunk -> IO.write(chunk) end,
            on_done: fn _ -> IO.puts("Complete!") end
          )
      \"\"\"
      @impl WishSdk.Prompt
      def stream(params, opts \\\\ []) do
        context_variables = to_context_variables(params)
        WishSdk.stream("#{prompt["slug"]}", Keyword.merge([context_variables: context_variables], opts))
      end

      defp to_context_variables(%__MODULE__{} = struct) do
        struct
        |> Map.from_struct()
        |> Enum.reject(fn {_, v} -> is_nil(v) end)
        |> Enum.into(%{})
      end

      defp to_context_variables(map) when is_map(map), do: map
      defp to_context_variables(keyword) when is_list(keyword), do: Enum.into(keyword, %{})
    end
    """

    File.write!(file_path, content)
    Mix.shell().info("  * creating #{file_path}")
    file_path
  end

  defp format_variables([]), do: "  None"

  defp format_variables(vars) do
    Enum.map_join(vars, "\n", fn var ->
      "  - `#{var["name"]}`: #{var["description"] || "No description"}"
    end)
  end

  defp format_example_fields(vars) when length(vars) == 0, do: ""

  defp format_example_fields(vars) do
    vars
    |> Enum.map(fn var -> "#{var["name"]}: \"...\"" end)
    |> Enum.join(", ")
  end

  defp format_example_params(vars) when length(vars) == 0, do: ""

  defp format_example_params(vars) do
    vars
    |> Enum.map(fn var -> "#{var["name"]}: \"...\"" end)
    |> Enum.join(", ")
  end
end
