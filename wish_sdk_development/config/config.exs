import Config

config :wish_sdk_development,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :wish_sdk_development, WishSdkDevelopmentWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: WishSdkDevelopmentWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: WishSdkDevelopment.PubSub,
  live_view: [signing_salt: "wish_sdk_dev"]

# Configure esbuild
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Wish SDK
config :wish_sdk,
  api_url: System.get_env("WISH_API_URL", "http://localhost:4000")

# Import environment specific config
import_config "#{config_env()}.exs"
