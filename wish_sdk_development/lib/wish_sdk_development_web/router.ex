defmodule WishSdkDevelopmentWeb.Router do
  use WishSdkDevelopmentWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WishSdkDevelopmentWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WishSdkDevelopmentWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/examples/invoke", Examples.InvokeLive
    live "/examples/stream", Examples.StreamLive
    live "/examples/live-prompt", Examples.LivePromptLive
    live "/examples/components", Examples.ComponentsLive
    live "/examples/generated", Examples.GeneratedLive
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:wish_sdk_development, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WishSdkDevelopmentWeb.Telemetry
    end
  end
end
