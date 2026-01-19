import Config

# Note we also include the path to a cache manifest
# containing the digested version of static files.
config :wish_sdk_development, WishSdkDevelopmentWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

config :wish_sdk,
  api_url: System.get_env("WISH_API_URL"),
  api_token: System.get_env("PLATFORM_INTERNAL_CALL_TOKEN"),
  timeout: 60_000
