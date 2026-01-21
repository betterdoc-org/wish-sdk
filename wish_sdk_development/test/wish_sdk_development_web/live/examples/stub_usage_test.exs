defmodule WishSdkDevelopmentWeb.Examples.StubUsageTest do
  @moduledoc """
  Example tests showing how to use WishSdk.Api.Stub in LiveView tests.

  This demonstrates testing patterns for:
  - Invoke operations with stubs
  - Stream operations with stubs
  - Error handling
  - Custom responses
  """
  use ExUnit.Case, async: true

  alias WishSdk.Api.Stub

  describe "using stubs in LiveView tests" do
    test "invoke with configured stub response" do
      # Configure stub response
      Stub.set_response("test-prompt", "Test response")

      # Call directly (not in a Task, to keep process dictionary state)
      result = WishSdk.invoke("test-prompt")
      assert {:ok, "Test response"} = result
    end

    test "stream with configured stub chunks" do
      test_pid = self()

      # Configure stub stream
      Stub.set_stream("test-prompt", ["Hello", " ", "test"], chunk_delay: 10)

      {:ok, task} =
        WishSdk.stream("test-prompt",
          on_chunk: fn chunk -> send(test_pid, {:chunk, chunk}) end,
          on_done: fn response -> send(test_pid, {:done, response}) end
        )

      Task.await(task)

      # Verify chunks received
      assert_received {:chunk, "Hello"}
      assert_received {:chunk, " "}
      assert_received {:chunk, "test"}
      assert_received {:done, "Hello test"}
    end

    test "uses default response when not configured" do
      # No configuration - should use default
      {:ok, response} = WishSdk.invoke("unconfigured-prompt")
      assert is_binary(response)
    end

    test "configures medical summary response" do
      test_pid = self()

      Stub.set_stream(
        "medical-summary",
        [
          "**Medical Case Summary**\n\n",
          "**Patient Information:**\n",
          "- Age: 45 years\n",
          "- Condition: Knee arthritis\n\n"
        ],
        chunk_delay: 5
      )

      {:ok, task} =
        WishSdk.stream("medical-summary",
          on_chunk: fn chunk -> send(test_pid, {:chunk, chunk}) end,
          on_done: fn _ -> send(test_pid, :done) end
        )

      Task.await(task)

      # Should receive medical-related content
      assert_received {:chunk, chunk}
      assert chunk =~ "Medical"
      assert_received :done
    end

    test "stub configuration is process-specific" do
      # Configure in this process
      Stub.set_response("test", "Process 1")

      # Spawn another process
      task =
        Task.async(fn ->
          # Different process, different configuration
          Stub.set_response("test", "Process 2")
          WishSdk.invoke("test")
        end)

      # Each process has its own configuration
      assert {:ok, "Process 1"} = WishSdk.invoke("test")
      assert {:ok, "Process 2"} = Task.await(task)
    end
  end

  describe "integration with LiveView patterns" do
    test "simulates invoke pattern from LiveView" do
      # This pattern matches what you'd do in a LiveView handle_event
      test_pid = self()

      Task.async(fn ->
        # Configure stub inside the Task (process dictionary is per-process)
        Stub.set_response("liveview-test", "LiveView response")
        # Simulate delay
        Process.sleep(10)

        case WishSdk.invoke("liveview-test") do
          {:ok, response} -> send(test_pid, {:invoke_done, response})
          {:error, reason} -> send(test_pid, {:invoke_error, reason})
        end
      end)

      assert_receive {:invoke_done, "LiveView response"}
    end

    test "simulates stream pattern from LiveView" do
      # Configure stub stream
      Stub.set_stream(
        "liveview-stream",
        ["Chunk ", "1", ", ", "Chunk ", "2"],
        chunk_delay: 5
      )

      # This pattern matches what you'd do in a LiveView handle_event
      test_pid = self()

      {:ok, _task} =
        WishSdk.stream("liveview-stream",
          on_chunk: fn chunk -> send(test_pid, {:chunk, chunk}) end,
          on_done: fn _ -> send(test_pid, :stream_done) end,
          on_error: fn error -> send(test_pid, {:stream_error, error}) end
        )

      # Verify chunks arrive
      assert_receive {:chunk, _}
      assert_receive :stream_done
    end
  end
end
