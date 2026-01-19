defmodule Mix.Tasks.Wish.List.Prompts do
  @moduledoc """
  Lists all available BetterPrompts from the Wish API.

  ## Usage

      mix wish.list.prompts

  ## Options

    * `--api-url` - Override the API URL (default: from config)

  ## Examples

      # List all prompts
      mix wish.list.prompts

      # List from specific API
      mix wish.list.prompts --api-url https://wish.mycompany.com
  """

  use Mix.Task

  @shortdoc "Lists all available BetterPrompts"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          api_url: :string
        ]
      )

    api_url = opts[:api_url] || Application.get_env(:wish_sdk, :api_url)

    unless api_url do
      Mix.raise("""
      No API URL configured. Please either:
      1. Set it in config.exs: config :wish_sdk, api_url: "https://your-wish-instance.com"
      2. Pass it as an option: mix wish.list.prompts --api-url https://your-wish-instance.com
      """)
    end

    Mix.shell().info("Fetching prompts from #{api_url}...\n")

    case WishSdk.fetch_schema(api_url: api_url) do
      {:ok, %{"prompts" => prompts}} ->
        Mix.shell().info("Available prompts (#{length(prompts)}):\n")

        Enum.each(prompts, fn prompt ->
          Mix.shell().info("  #{prompt["slug"]}")
          Mix.shell().info("    Name: #{prompt["name"]}")

          if prompt["description"] && prompt["description"] != "" do
            Mix.shell().info("    Description: #{prompt["description"]}")
          end

          required_vars = prompt["required_context_variables"] || []

          if length(required_vars) > 0 do
            var_names = Enum.map_join(required_vars, ", ", & &1["name"])
            Mix.shell().info("    Required: #{var_names}")
          end

          Mix.shell().info("")
        end)

        Mix.shell().info("""
        To generate a module for a prompt, run:
          mix wish.gen.prompt SLUG

        Example:
          mix wish.gen.prompt #{List.first(prompts)["slug"]}
        """)

      {:error, error} ->
        Mix.raise("Failed to fetch prompts: #{inspect(error)}")
    end
  end
end
