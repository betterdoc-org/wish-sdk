import Config

# Configure WishSdk to use stub implementation in tests
config :wish_sdk, WishSdk.Api, WishSdk.Api.Stub
