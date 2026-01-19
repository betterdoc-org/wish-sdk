# Configure WishSdk to use stub in tests
Application.put_env(:wish_sdk, WishSdk.Api, WishSdk.Api.Stub)

ExUnit.start()
