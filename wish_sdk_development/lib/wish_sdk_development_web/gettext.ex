defmodule WishSdkDevelopmentWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.
  """
  use Gettext.Backend, otp_app: :wish_sdk_development
end
