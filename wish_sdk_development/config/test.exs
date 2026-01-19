import Config

# We don't run a server during test
config :wish_sdk_development, WishSdkDevelopmentWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_that_is_at_least_64_bytes_long_for_testing",
  server: false

# Configure WishSdk to use stub in tests
config :wish_sdk, WishSdk.Api, WishSdk.Api.Stub

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
