defmodule WishSdkDevelopmentWeb.Examples.GeneratedLive do
  use WishSdkDevelopmentWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
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

      <h1 class="text-4xl font-bold mb-4">Generated Modules Example</h1>
      <p class="text-gray-600 mb-8">
        Demonstrates type-safe modules generated from the Wish API schema using Mix tasks.
      </p>

      <div class="space-y-8">
        <!-- Mix Task -->
        <div class="bg-white rounded-lg shadow-lg p-6">
          <h2 class="text-2xl font-semibold mb-4">Step 1 - Generate Modules</h2>
          <p class="text-gray-600 mb-4">
            Run the Mix task to generate type-safe modules from your Wish API:
          </p>
          <pre class="bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>mix wish.gen.prompts

    # With options:
    mix wish.gen.prompts --api-url https://wish.mycompany.com --output-dir lib/prompts</code></pre>

          <div class="mt-4 bg-blue-50 border border-blue-200 rounded p-4">
            <p class="text-blue-800 text-sm">
              The task will fetch all published prompts and generate an Ecto schema module for each one.
            </p>
          </div>
        </div>
        <!-- Generated Module Example -->
        <div class="bg-white rounded-lg shadow-lg p-6">
          <h2 class="text-2xl font-semibold mb-4">Step 2 - Generated Module Structure</h2>
          <p class="text-gray-600 mb-4">
            For a prompt with slug "medical-summary", you'll get:
          </p>
          <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto">
            <code>
    defmodule MyApp.Prompts.MedicalSummary do
    # Auto-generated module for 'medical-summary' BetterPrompt

    use Ecto.Schema
    import Ecto.Changeset

    # Compile-time safety!
    @enforce_keys [:case_id, :document_id]

    embedded_schema do
    field :case_id, :string
    field :document_id, :string
    end

    def invoke(params, opts \\ []) do
    context_variables = to_context_variables(params)
    WishSdk.invoke("medical-summary",
      Keyword.merge([context_variables: context_variables], opts))
    end

    def stream(params, opts \\ []) do
    context_variables = to_context_variables(params)
    WishSdk.stream("medical-summary",
      Keyword.merge([context_variables: context_variables], opts))
    end

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
            </code>
          </pre>
        </div>
        <!-- Usage Examples -->
        <div class="bg-white rounded-lg shadow-lg p-6">
          <h2 class="text-2xl font-semibold mb-4">Step 3 - Use the Generated Module</h2>

          <div class="space-y-6">
            <div>
              <h3 class="text-lg font-semibold mb-2 text-green-700">
                Pattern 1 - Direct Struct Literals
              </h3>
              <p class="text-xs text-green-600 mb-2">(Recommended approach)</p>
              <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>alias MyApp.Prompts.MedicalSummary

    # Compile-time safe - won't compile if fields missing!
    %MedicalSummary{case_id: "123", document_id: "456"}
    |> WishSdk.invoke()

    # Or use module helper
    MedicalSummary.invoke(case_id: "123", document_id: "456")

    # Streaming
    %MedicalSummary{case_id: "123", document_id: "456"}
    |> WishSdk.stream(
    on_chunk: fn chunk -> IO.write(chunk) end,
    on_done: fn _ -> IO.puts("\nDone!") end
    )</code></pre>
            </div>

            <div>
              <h3 class="text-lg font-semibold mb-2">
                Pattern 2 - With Pattern Matching
              </h3>
              <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>alias MyApp.Prompts.MedicalSummary

    # Idiomatic Elixir!
    def process_case(%{"case_id" => id, "document_id" => doc}) do
    prompt = %MedicalSummary{case_id: id, document_id: doc}
    WishSdk.invoke(prompt)
    end

    # Works with guards and pattern matching
    def process(%MedicalSummary{case_id: id} = prompt)
    when byte_size(id) > 0 do
    WishSdk.invoke(prompt)
    end</code></pre>
            </div>

            <div>
              <h3 class="text-lg font-semibold mb-2">Compile-Time Errors</h3>
              <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code># ❌ Won't compile - missing document_id
    %MedicalSummary{case_id: "123"}
    # => ** (ArgumentError) the following keys must also be given
    #    when building struct MedicalSummary: [:document_id]

    # ❌ Won't compile - typo in field name
    %MedicalSummary{cas_id: "123", document_id: "456"}
    # => ** (KeyError) key :cas_id not found

    # ❌ Dialyzer warning - wrong type
    %MedicalSummary{case_id: 123, document_id: "456"}
    # => Warning: expected string(), got 123</code></pre>
            </div>
          </div>
        </div>
        <!-- Benefits -->
        <div class="bg-white rounded-lg shadow-lg p-6">
          <h2 class="text-2xl font-semibold mb-4">Benefits</h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="bg-green-50 border border-green-200 rounded p-4">
              <h4 class="font-semibold text-green-900 mb-2">Compile-Time Safety</h4>
              <p class="text-sm text-green-800">
                @enforce_keys catches missing fields at compile time, not runtime
              </p>
            </div>

            <div class="bg-green-50 border border-green-200 rounded p-4">
              <h4 class="font-semibold text-green-900 mb-2">Idiomatic Elixir</h4>
              <p class="text-sm text-green-800">
                Standard struct syntax with pattern matching and guards
              </p>
            </div>

            <div class="bg-green-50 border border-green-200 rounded p-4">
              <h4 class="font-semibold text-green-900 mb-2">Dialyzer Support</h4>
              <p class="text-sm text-green-800">
                Type checking with Dialyzer for additional compile-time safety
              </p>
            </div>

            <div class="bg-green-50 border border-green-200 rounded p-4">
              <h4 class="font-semibold text-green-900 mb-2">IDE Autocomplete</h4>
              <p class="text-sm text-green-800">
                Field suggestions and inline documentation in your editor
              </p>
            </div>
          </div>
        </div>
        <!-- Re-generation -->
        <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <h3 class="text-yellow-900 font-semibold mb-2">Schema Changes</h3>
          <p class="text-yellow-800">
            When your Wish prompts change (new required fields, renamed variables, etc.),
            re-run <code class="bg-yellow-100 px-2 py-1 rounded">mix wish.gen.prompts</code>
            to update the generated modules.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
