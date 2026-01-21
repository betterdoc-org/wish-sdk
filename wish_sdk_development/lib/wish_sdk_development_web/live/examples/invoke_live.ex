defmodule WishSdkDevelopmentWeb.Examples.InvokeLive do
  use WishSdkDevelopmentWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:slug, "")
     |> assign(:context_variables, "{\n  \"case_id\": \"123\"\n}")
     |> assign(:user_prompt, "")
     |> assign(:response, "")
     |> assign(:status, :idle)
     |> assign(:error, nil)}
  end

  @impl true
  def handle_event("invoke", %{"slug" => slug, "context" => context, "prompt" => prompt}, socket) do
    # Persist user input values and set loading state
    socket =
      assign(socket,
        slug: slug,
        context_variables: context,
        user_prompt: prompt,
        status: :connecting,
        error: nil,
        response: ""
      )

    # Parse context variables
    context_vars =
      case Jason.decode(context) do
        {:ok, vars} -> vars
        {:error, _} -> %{}
      end

    opts = [context_variables: context_vars]
    opts = if prompt != "", do: Keyword.put(opts, :user_prompt, prompt), else: opts

    # Start async task to make the API call
    # This allows the UI to update with the loading spinner
    Task.async(fn ->
      WishSdk.invoke(slug, opts)
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, result}, socket) when is_reference(ref) do
    # Task completed
    Process.demonitor(ref, [:flush])

    case result do
      {:ok, response} ->
        {:noreply,
         socket
         |> assign(:response, response)
         |> assign(:status, :done)}

      {:error, error} ->
        {:noreply,
         socket
         |> assign(:error, error)
         |> assign(:status, :error)}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, :normal}, socket) do
    # Task process terminated normally
    {:noreply, socket}
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

      <h1 class="text-4xl font-bold mb-4">Invoke API Example</h1>
      <p class="text-gray-600 mb-4">
        Demonstrates <code class="bg-gray-100 px-2 py-1 rounded">WishSdk.invoke/2</code>
        for synchronous prompt invocation.
      </p>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div>
          <h2 class="text-2xl font-semibold mb-4">Configuration</h2>

          <form phx-submit="invoke" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Prompt Slug
              </label>
              <input
                type="text"
                name="slug"
                value={@slug}
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                placeholder="medical-summary"
                required
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Context Variables (JSON)
              </label>
              <textarea
                name="context"
                rows="6"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 font-mono text-sm"
                required
              ><%= @context_variables %></textarea>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                User Prompt (optional)
              </label>
              <textarea
                name="prompt"
                rows="3"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                placeholder="What are the key findings?"
              ><%= @user_prompt %></textarea>
            </div>

            <button
              type="submit"
              disabled={@status == :connecting}
              class="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              <%= if @status == :connecting, do: "Invoking...", else: "Invoke Prompt" %>
            </button>
          </form>

          <div class="mt-6 space-y-4">
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="font-semibold mb-2">Code (Raw API):</h3>
              <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code>WishSdk.invoke("<%= @slug %>",
    context_variables: <%= @context_variables %><%= if @user_prompt != "", do: ",\n  user_prompt: \"#{@user_prompt}\"" %>
    )</code></pre>
            </div>

            <div class="bg-blue-50 rounded-lg p-4">
              <h3 class="font-semibold mb-2 text-blue-900">
                💡 Better: Use Generated Prompts
              </h3>
              <pre class="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto"><code># After running: mix wish.gen.prompts
    alias MyApp.Prompts.MedicalSummary

    # Compile-time safe!
    %MedicalSummary{case_id: "123", document_id: "456"}
    |> WishSdk.invoke(user_prompt: "Summarize")</code></pre>
              <p class="text-sm text-blue-800 mt-2">
                See the
                <.link navigate={~p"/examples/generated"} class="underline hover:text-blue-600">
                  Generated Modules
                </.link>
                example to learn more.
              </p>
            </div>
          </div>
        </div>

        <div>
          <h2 class="text-2xl font-semibold mb-4">Response</h2>

          <.wish_response
            content={@response}
            status={@status}
            error={@error}
            show_status={true}
            loading_size="large"
            auto_scroll={false}
            empty_message="Enter configuration and click 'Invoke Prompt' to see results"
            class="bg-white border border-gray-200 rounded-lg p-6 min-h-[200px]"
          />
        </div>
      </div>
    </div>
    """
  end
end
