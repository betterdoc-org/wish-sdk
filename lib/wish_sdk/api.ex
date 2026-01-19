defmodule WishSdk.Api do
  @moduledoc """
  API client behavior for Wish BetterPrompt.

  Configure the implementation via config:

      # Use real API client (default - no config needed)

      # Use stub for testing
      config :wish_sdk, WishSdk.Api, WishSdk.Api.Stub
  """

  use Knigge,
    otp_app: :wish_sdk,
    default: WishSdk.Api.Client

  @callback invoke(
              prompt_or_slug :: struct() | String.t(),
              opts :: keyword()
            ) :: {:ok, String.t()} | {:error, any()}

  @callback stream(
              prompt_or_slug :: struct() | String.t(),
              opts :: keyword()
            ) :: {:ok, Task.t()} | {:error, any()}

  @callback fetch_schema(opts :: keyword()) :: {:ok, list(map())} | {:error, any()}

  @callback fetch_prompt_schema(slug :: String.t(), opts :: keyword()) ::
              {:ok, map()} | {:error, any()}
end
