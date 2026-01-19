defmodule WishSdk.Prompt do
  @moduledoc """
  Behaviour for generated prompt modules.

  This module provides multiple idiomatic Elixir patterns for working with prompts.

  ## Direct Struct Creation (Fast, Idiomatic)

  When you trust your data or are constructing prompts programmatically:

      alias MyApp.Prompts.MedicalSummary

      # Pure Elixir struct syntax
      %MedicalSummary{case_id: "123", document_id: "456"}
      |> WishSdk.invoke()

      # Works with pattern matching
      prompt = %MedicalSummary{case_id: id, document_id: doc}

      # Composable with struct update syntax
      %MedicalSummary{prompt | case_id: new_id}
      |> WishSdk.invoke()

  ## Validated Construction (For User Input)

  When you need custom validation beyond required fields (user input, external data):

      # Returns {:ok, struct} or {:error, changeset}
      case MedicalSummary.new(user_params) do
        {:ok, prompt} -> WishSdk.invoke(prompt)
        {:error, changeset} -> handle_errors(changeset)
      end

  ## One-Liner (Convenient)

  When you just want to invoke directly:

      MedicalSummary.invoke(case_id: "123", document_id: "456")

  ## Type Specifications

  All generated modules work with Dialyzer for compile-time type checking:

      @spec process(MedicalSummary.t()) :: {:ok, String.t()}
      def process(%MedicalSummary{} = prompt) do
        WishSdk.invoke(prompt)
      end
  """

  @type t :: struct()
  @type params :: map() | keyword()
  @type invoke_opts :: keyword()

  @doc """
  Creates a new prompt struct with validation (optional).
  Returns `{:ok, struct}` or `{:error, changeset}`.

  Only needed if you have custom validation rules beyond required fields.
  For most cases, use direct struct creation with compile-time safety.
  """
  @callback new(params()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}

  @doc """
  Invokes the prompt with the given parameters or struct.
  """
  @callback invoke(params() | t(), invoke_opts()) :: {:ok, String.t()} | {:error, term()}

  @doc """
  Streams the prompt response with the given parameters or struct.
  """
  @callback stream(params() | t(), invoke_opts()) :: {:ok, Task.t()} | {:error, term()}

  @doc """
  Returns the prompt slug.
  """
  @callback slug() :: String.t()

  @doc """
  Extracts the prompt slug and context variables from a prompt struct
  for use with WishSdk.invoke/2 or WishSdk.stream/2.

  This enables direct struct creation to work with the SDK:

      %MedicalSummary{case_id: "123"}
      |> WishSdk.invoke()  # Works!
  """
  def to_opts(%module{} = struct) do
    if function_exported?(module, :slug, 0) do
      slug = module.slug()

      context_variables =
        struct
        |> Map.from_struct()
        |> Enum.reject(fn {_, v} -> is_nil(v) end)
        |> Enum.into(%{})

      {slug, context_variables: context_variables}
    else
      raise ArgumentError, "#{inspect(module)} is not a WishSdk.Prompt"
    end
  end
end
