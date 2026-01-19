defmodule Mix.Tasks.Wish.Gen.Prompts do
  @moduledoc """
  Generates type-safe Elixir modules for BetterPrompts from the Wish API schema.

  ## Usage

      mix wish.gen.prompts

  ## Options

    * `--api-url` - Override the API URL (default: from config)
    * `--output-dir` - Output directory for generated modules (default: lib/wish_prompts)
    * `--module-prefix` - Module prefix (default: YourApp.Prompts)
    * `--only` - Comma-separated list of prompt slugs to generate
    * `--except` - Comma-separated list of prompt slugs to exclude

  ## Examples

      # Generate from configured API
      mix wish.gen.prompts

      # Generate only specific prompts
      mix wish.gen.prompts --only medical-summary,case-analyzer

      # Generate all except test prompts
      mix wish.gen.prompts --except test-prompt,debug-helper

      # Generate with custom API URL
      mix wish.gen.prompts --api-url https://wish.mycompany.com

      # Generate with custom output directory
      mix wish.gen.prompts --output-dir lib/my_app/prompts --module-prefix MyApp.Prompts

  ## What it does

  This task fetches the schema from your Wish API and generates:

  1. An embedded schema module for each prompt with all required context variables
  2. Validation functions using Ecto.Changeset
  3. Helper functions for invoking and streaming the prompt

  ## Generated code example

      defmodule MyApp.Prompts.MedicalSummary do
        use Ecto.Schema
        import Ecto.Changeset

        @moduledoc \"\"\"
        Auto-generated module for the 'medical-summary' BetterPrompt.

        Description: Generates medical case summaries

        Required context variables:
        - case_id: The case ID to load
        - document_id: The document to analyze
        \"\"\"

        embedded_schema do
          field :case_id, :string
          field :document_id, :string
        end

        def changeset(params) do
          %__MODULE__{}
          |> cast(params, [:case_id, :document_id])
          |> validate_required([:case_id, :document_id])
        end

        def new!(params) do
          changeset(params)
          |> apply_action!(:insert)
        end

        def invoke(params, opts \\\\ []) do
          context_variables = to_context_variables(params)
          WishSdk.invoke("medical-summary", Keyword.merge([context_variables: context_variables], opts))
        end

        def stream(params, opts \\\\ []) do
          context_variables = to_context_variables(params)
          WishSdk.stream("medical-summary", Keyword.merge([context_variables: context_variables], opts))
        end

        defp to_context_variables(%__MODULE__{} = struct) do
          struct
          |> Map.from_struct()
          |> Enum.reject(fn {_, v} -> is_nil(v) end)
          |> Enum.into(%{})
        end

        defp to_context_variables(map) when is_map(map), do: map
      end
  """

  use Mix.Task

  @shortdoc "Generates type-safe modules for BetterPrompts"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _} =
      OptionParser.parse!(args,
        strict: [
          api_url: :string,
          output_dir: :string,
          module_prefix: :string,
          only: :string,
          except: :string
        ]
      )

    api_url = opts[:api_url] || Application.get_env(:wish_sdk, :api_url)
    output_dir = opts[:output_dir] || "lib/wish_prompts"
    module_prefix = opts[:module_prefix] || infer_module_prefix()
    only_slugs = parse_slug_list(opts[:only])
    except_slugs = parse_slug_list(opts[:except])

    unless api_url do
      Mix.raise("""
      No API URL configured. Please either:
      1. Set it in config.exs: config :wish_sdk, api_url: "https://your-wish-instance.com"
      2. Pass it as an option: mix wish.gen.prompts --api-url https://your-wish-instance.com
      """)
    end

    Mix.shell().info("Fetching schema from #{api_url}...")

    case WishSdk.fetch_schema(api_url: api_url) do
      {:ok, %{"prompts" => prompts}} ->
        filtered_prompts = filter_prompts(prompts, only_slugs, except_slugs)

        if Enum.empty?(filtered_prompts) do
          Mix.shell().error("""
          No prompts matched your filters.
          Found #{length(prompts)} total prompt(s), but none matched:
            --only: #{inspect(only_slugs)}
            --except: #{inspect(except_slugs)}
          """)
        else
          Mix.shell().info(
            "Found #{length(prompts)} prompt(s), generating #{length(filtered_prompts)}"
          )

          File.mkdir_p!(output_dir)

          Enum.each(filtered_prompts, fn prompt ->
            generate_prompt_module(prompt, output_dir, module_prefix)
          end)

          Mix.shell().info("""

          ✓ Generated #{length(filtered_prompts)} prompt module(s) in #{output_dir}/

          Generated prompts:
          #{Enum.map_join(filtered_prompts, "\n", fn p -> "  - #{p["slug"]}" end)}
          """)
        end

      {:error, error} ->
        Mix.raise("Failed to fetch schema: #{inspect(error)}")
    end
  end

  defp parse_slug_list(nil), do: []

  defp parse_slug_list(str) when is_binary(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp filter_prompts(prompts, [], []), do: prompts

  defp filter_prompts(prompts, only_slugs, []) when length(only_slugs) > 0 do
    Enum.filter(prompts, fn prompt ->
      prompt["slug"] in only_slugs
    end)
  end

  defp filter_prompts(prompts, [], except_slugs) when length(except_slugs) > 0 do
    Enum.reject(prompts, fn prompt ->
      prompt["slug"] in except_slugs
    end)
  end

  defp filter_prompts(prompts, only_slugs, except_slugs) do
    # If both are specified, only takes precedence
    prompts
    |> Enum.filter(fn prompt -> prompt["slug"] in only_slugs end)
    |> Enum.reject(fn prompt -> prompt["slug"] in except_slugs end)
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

  defp generate_prompt_module(prompt, output_dir, module_prefix) do
    slug = prompt["slug"]
    name = prompt["name"]
    description = prompt["description"]
    required_vars = prompt["required_context_variables"] || []
    optional_vars = prompt["optional_context_variables"] || []

    module_name = slug_to_module_name(slug)
    full_module = "#{module_prefix}.#{module_name}"
    file_name = Macro.underscore(module_name) <> ".ex"
    file_path = Path.join(output_dir, file_name)

    content =
      generate_module_content(full_module, slug, name, description, required_vars, optional_vars)

    File.write!(file_path, content)
    Mix.shell().info("  • Generated #{full_module} -> #{file_path}")
  end

  defp slug_to_module_name(slug) do
    slug
    |> String.split("-")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join()
  end

  defp generate_module_content(module_name, slug, name, description, required_vars, optional_vars) do
    all_vars = required_vars ++ optional_vars
    _required_var_names = Enum.map(required_vars, & &1["name"])

    """
    defmodule #{module_name} do
      @moduledoc \"\"\"
      Auto-generated module for the '#{slug}' BetterPrompt.

      **Name:** #{name}

      **Description:** #{description}

      ## Required context variables

    #{format_variables(required_vars)}

      ## Optional context variables

    #{format_variables(optional_vars)}

      ## Usage

          alias #{module_name}

          # Direct struct (cleanest, compile-time safe!)
          %#{module_name}{case_id: "123", document_id: "456"}
          |> WishSdk.invoke()

          # One-liner helper
          #{module_name}.invoke(case_id: "123", document_id: "456")

          # With validation (for user input)
          case #{module_name}.new(user_params) do
            {:ok, prompt} -> WishSdk.invoke(prompt)
            {:error, changeset} -> {:error, changeset.errors}
          end

          # Stream response
          %#{module_name}{case_id: "123", document_id: "456"}
          |> WishSdk.stream(
            on_chunk: fn chunk -> IO.write(chunk) end,
            on_done: fn _ -> IO.puts("\\nDone!") end
          )
      \"\"\"

      use Ecto.Schema
      import Ecto.Changeset

      @behaviour WishSdk.Prompt

      # Enforce required keys at compile time!
      @enforce_keys [#{format_field_list(required_vars)}]

      embedded_schema do
    #{format_fields(all_vars)}
      end

      @doc \"\"\"
      Returns the prompt slug.
      \"\"\"
      @impl WishSdk.Prompt
      def slug, do: "#{slug}"

      @doc \"\"\"
      Creates a changeset for validation.

      By default, only validates required fields (which `@enforce_keys` already does at compile-time).

      **Add custom validation rules here if needed:**

          def changeset(struct, params) do
            struct
            |> cast(params, [...])
            |> validate_required([...])
            |> validate_format(:field, ~r/pattern/)  # ← Add custom rules!
            |> validate_length(:field, min: 3)        # ← Add custom rules!
          end
      \"\"\"
      def changeset(struct \\\\ %__MODULE__{}, params) do
        params = normalize_params(params)

        struct
        |> cast(params, [#{format_field_list(all_vars)}])
        |> validate_required([#{format_field_list(required_vars)}])
      end

      @doc \"\"\"
      Creates a new struct with validation.
      Returns {:ok, struct} or {:error, changeset}.

      **NOTE:** Without custom validation rules in `changeset/2`, this just checks
      what `@enforce_keys` already checks at compile-time.

      Only use this if you've added custom validations to `changeset/2`.

      **For most cases, use direct struct creation:**

          %#{module_name}{case_id: "...", document_id: "..."}
      \"\"\"
      @impl WishSdk.Prompt
      def new(params) do
        changeset(params)
        |> apply_action(:insert)
      end

      @doc \"\"\"
      Invokes the prompt and returns the complete response.

      Accepts a struct, map, or keyword list of context variables.

      ## Examples

          # Direct struct (recommended, compile-time safe)
          %__MODULE__{case_id: "123", document_id: "456"}
          |> WishSdk.invoke()

          # One-liner
          invoke(case_id: "123", document_id: "456")

          # With validation (for user input)
          case new(user_params) do
            {:ok, prompt} -> invoke(prompt)
            {:error, changeset} -> {:error, changeset}
          end
      \"\"\"
      @impl WishSdk.Prompt
      def invoke(params, opts \\\\ []) do
        context_variables = to_context_variables(params)
        WishSdk.invoke("#{slug}", Keyword.merge([context_variables: context_variables], opts))
      end

      @doc \"\"\"
      Streams the prompt response with real-time chunks.

      Accepts a struct, map, or keyword list of context variables.

      ## Options

      - `:on_chunk` - Callback for each chunk
      - `:on_done` - Callback when complete
      - `:on_error` - Callback on error
      - `:on_connected` - Callback when connected

      ## Examples

          # Direct struct (recommended)
          %__MODULE__{case_id: "123", document_id: "456"}
          |> WishSdk.stream(on_chunk: fn chunk -> IO.write(chunk) end)

          # One-liner
          stream([case_id: "123", document_id: "456"],
            on_chunk: fn chunk -> IO.write(chunk) end
          )
      \"\"\"
      @impl WishSdk.Prompt
      def stream(params, opts \\\\ []) do
        context_variables = to_context_variables(params)
        WishSdk.stream("#{slug}", Keyword.merge([context_variables: context_variables], opts))
      end

      defp normalize_params(params) when is_list(params), do: Enum.into(params, %{})
      defp normalize_params(params) when is_map(params), do: params

      defp to_context_variables(%__MODULE__{} = struct) do
        struct
        |> Map.from_struct()
        |> Enum.reject(fn {_, v} -> is_nil(v) end)
        |> Enum.into(%{})
      end

      defp to_context_variables(params) when is_list(params) do
        Enum.into(params, %{})
      end

      defp to_context_variables(map) when is_map(map), do: map
    end
    """
  end

  defp format_variables([]), do: "  None"

  defp format_variables(variables) do
    variables
    |> Enum.map(fn var ->
      "  - `#{var["name"]}`: #{var["description"]}"
    end)
    |> Enum.join("\n")
  end

  defp format_fields(variables) do
    variables
    |> Enum.map(fn var ->
      "    field :#{var["name"]}, :string"
    end)
    |> Enum.join("\n")
  end

  defp format_field_list(variables) do
    variables
    |> Enum.map(&":#{&1["name"]}")
    |> Enum.join(", ")
  end
end
