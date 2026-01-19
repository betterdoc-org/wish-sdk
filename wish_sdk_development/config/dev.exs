import Config

config :wish_sdk_development, WishSdkDevelopmentWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4001],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "wish_sdk_development_secret_key_base_for_dev_only_do_not_use_in_production",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

config :wish_sdk_development, WishSdkDevelopmentWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/wish_sdk_development_web/(controllers|live|components)/.*(ex|heex)$",
      ~r"lib/wish_sdk/.*(ex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
config :phoenix_live_view, :debug_heex_annotations, true

config :wish_sdk,
  api_url: "http://localhost:4000/",
  api_token: "dummy_token",
  timeout: 60_000
