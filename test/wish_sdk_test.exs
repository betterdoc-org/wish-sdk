defmodule WishSdkTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Tests for WishSdk main module.

  These tests verify that Knigge delegation works properly.
  In test environment, WishSdk.Api is configured to use WishSdk.Api.Stub,
  so all calls through WishSdk.invoke/2 and WishSdk.stream/2 automatically
  use the stub implementation.
  """

  test "invoke delegates to configured implementation (stub in test)" do
    # Configure stub response
    WishSdk.Api.Stub.set_response("test-prompt", "Test response")

    # This uses WishSdk.Api.Stub automatically because of config/test.exs
    result = WishSdk.invoke("test-prompt")

    assert {:ok, "Test response"} = result
  end

  test "stream delegates to configured implementation (stub in test)" do
    test_pid = self()

    # Configure stub stream
    WishSdk.Api.Stub.set_stream("test-prompt", ["Hello", " ", "world"], chunk_delay: 10)

    # This uses WishSdk.Api.Stub automatically because of config/test.exs
    {:ok, task} =
      WishSdk.stream("test-prompt",
        on_chunk: fn chunk -> send(test_pid, {:chunk, chunk}) end,
        on_done: fn response -> send(test_pid, {:done, response}) end
      )

    Task.await(task)

    assert_received {:chunk, "Hello"}
    assert_received {:chunk, " "}
    assert_received {:chunk, "world"}
    assert_received {:done, "Hello world"}
  end

  test "fetch_schema delegates to stub" do
    {:ok, schemas} = WishSdk.fetch_schema()

    assert is_list(schemas)
    assert length(schemas) > 0
    assert %{"slug" => "medical-summary"} = Enum.at(schemas, 0)
  end

  test "fetch_prompt_schema delegates to stub" do
    {:ok, schema} = WishSdk.fetch_prompt_schema("medical-summary")

    assert schema["slug"] == "medical-summary"
    assert schema["name"] == "Medical Summary"
  end

  test "fetch_prompt_schema returns error for unknown prompt" do
    {:error, error} = WishSdk.fetch_prompt_schema("unknown-prompt")

    assert error.status == 404
  end
end
