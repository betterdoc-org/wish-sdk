defmodule WishSdk.Api.StubTest do
  use ExUnit.Case, async: true

  alias WishSdk.Api.Stub

  setup do
    # Clear stub configuration before each test
    Stub.clear()
    :ok
  end

  describe "invoke/2" do
    test "returns configured response for slug" do
      Stub.set_response("test-prompt", "Custom response")

      assert {:ok, "Custom response"} = Stub.invoke("test-prompt")
    end

    test "returns default response when not configured" do
      assert {:ok, response} = Stub.invoke("unconfigured-prompt")
      assert is_binary(response)
      assert response =~ "stub response"
    end

    test "works with prompt structs" do
      Stub.set_response("my-prompt", "Struct response")

      prompt = %{__wish_prompt__: "my-prompt", case_id: "123"}
      assert {:ok, "Struct response"} = Stub.invoke(prompt)
    end
  end

  describe "stream/2" do
    test "streams configured chunks" do
      test_pid = self()

      Stub.set_stream("test-prompt", ["Hello", " ", "world"], chunk_delay: 10)

      {:ok, task} =
        Stub.stream("test-prompt",
          on_chunk: fn chunk -> send(test_pid, {:chunk, chunk}) end,
          on_done: fn response -> send(test_pid, {:done, response}) end
        )

      Task.await(task)

      assert_received {:chunk, "Hello"}
      assert_received {:chunk, " "}
      assert_received {:chunk, "world"}
      assert_received {:done, "Hello world"}
    end

    test "streams default chunks when not configured" do
      test_pid = self()

      {:ok, task} =
        Stub.stream("unconfigured-prompt",
          on_chunk: fn chunk -> send(test_pid, {:chunk, chunk}) end,
          on_done: fn _ -> send(test_pid, :done) end
        )

      Task.await(task)

      # Should receive some chunks
      assert_received {:chunk, _}
      assert_received :done
    end

    test "calls on_connected callback" do
      test_pid = self()

      {:ok, task} =
        Stub.stream("test-prompt",
          on_connected: fn -> send(test_pid, :connected) end,
          on_chunk: fn _ -> :ok end
        )

      Task.await(task)
      assert_received :connected
    end
  end

  describe "configuration helpers" do
    test "set_response/2 configures response per process" do
      Stub.set_response("test", "Response 1")
      assert {:ok, "Response 1"} = Stub.invoke("test")

      Stub.set_response("test", "Response 2")
      assert {:ok, "Response 2"} = Stub.invoke("test")
    end

    test "set_stream/2 configures chunks per process" do
      test_pid = self()

      Stub.set_stream("test", ["A", "B"])

      {:ok, task} =
        Stub.stream("test",
          on_chunk: fn chunk -> send(test_pid, {:chunk, chunk}) end
        )

      Task.await(task)

      assert_received {:chunk, "A"}
      assert_received {:chunk, "B"}
    end

    test "clear/0 removes all configurations" do
      Stub.set_response("test1", "Response 1")
      Stub.set_response("test2", "Response 2")
      Stub.set_stream("test3", ["A"])

      Stub.clear()

      # Should use defaults now
      assert {:ok, response} = Stub.invoke("test1")
      refute response == "Response 1"
    end
  end

  describe "fetch_schema/1" do
    test "returns default schema" do
      {:ok, schemas} = Stub.fetch_schema()

      assert is_list(schemas)
      assert length(schemas) > 0
      assert %{"slug" => "medical-summary"} = Enum.at(schemas, 0)
    end
  end

  describe "fetch_prompt_schema/2" do
    test "returns schema for known prompt" do
      {:ok, schema} = Stub.fetch_prompt_schema("medical-summary")

      assert schema["slug"] == "medical-summary"
      assert schema["name"] == "Medical Summary"
    end

    test "returns error for unknown prompt" do
      {:error, error} = Stub.fetch_prompt_schema("unknown-prompt")

      assert error.status == 404
    end
  end
end
