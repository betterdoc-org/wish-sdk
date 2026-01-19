# WishSdk Development & Showcase

Interactive showcase application demonstrating all WishSdk features with live examples and documentation.

## Features

This application demonstrates:

- **Invoke API**: Synchronous prompt invocation
- **Stream API**: Real-time streaming responses
- **LiveView Components**: Pre-built UI components
- **Generated Modules**: Type-safe modules from schema
- **Interactive Examples**: Try all features with live code examples

## Setup

### Prerequisites

- Elixir 1.14 or later
- A running Wish instance (configure the API URL)

### Installation

```bash
# Install dependencies
mix deps.get

# Setup assets
mix assets.setup

# Configure your Wish API URL
export WISH_API_URL=http://localhost:4000
# Or edit config/dev.exs

# Start the server
mix phx.server
```

Visit http://localhost:4001

## Configuration

Set your Wish API URL in `config/dev.exs`:

```elixir
config :wish_sdk,
  api_url: "https://your-wish-instance.com"
```

Or set it via environment variable:

```bash
export WISH_API_URL=https://your-wish-instance.com
```

## Development

This application is set up with live reload enabled. Any changes to:

- `lib/wish_sdk_development_web/**/*.ex`
- `lib/wish_sdk/**/*.ex` (the parent SDK)
- `assets/**/*`

Will automatically reload the page.

## Examples Included

### 1. Invoke API (`/examples/invoke`)
- Simple synchronous invocation
- Complete response handling
- Error handling examples

### 2. Stream API (`/examples/stream`)
- Real-time streaming
- Chunk-by-chunk updates
- Callback demonstrations

### 3. LiveView Components (`/examples/components`)
- `<.wish_prompt />` component
- `<.wish_response />` component
- `<.wish_status />` component
- Event handling

### 4. Generated Modules (`/examples/generated`)
- Type-safe module generation
- Validation examples
- Mix task documentation

## Structure

```
wish_sdk_development/
├── lib/
│   ├── wish_sdk_development/
│   │   └── application.ex
│   ├── wish_sdk_development_web/
│   │   ├── components/
│   │   │   ├── core_components.ex
│   │   │   └── layouts/
│   │   ├── live/
│   │   │   ├── home_live.ex
│   │   │   └── examples/
│   │   │       ├── invoke_live.ex
│   │   │       ├── stream_live.ex
│   │   │       ├── components_live.ex
│   │   │       └── generated_live.ex
│   │   ├── endpoint.ex
│   │   └── router.ex
│   └── wish_sdk_development_web.ex
├── assets/
│   ├── js/
│   │   └── app.js
│   ├── css/
│   │   └── app.css
│   └── tailwind.config.js
└── config/
    ├── config.exs
    └── dev.exs
```

## Testing SDK Features

All examples are interactive. You can:

1. Modify the prompt slug
2. Change context variables
3. Add user prompts
4. See real API calls in action

## Notes

- Examples require a running Wish instance with published prompts
- The streaming examples demonstrate real-time SSE handling
- Component examples show both JavaScript and pure Elixir approaches

## Learn More

- [WishSdk Documentation](../README.md)
- [Wish API Documentation](https://github.com/yourusername/wish)
- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
