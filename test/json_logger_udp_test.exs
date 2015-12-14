defmodule Logger.Backends.JSON.UDPTest do
  use ExUnit.Case, async: false
  require Logger

  @backend {Logger.Backends.JSON, :test}

  @message "Yo"
  @metadata "Very important data"
  @level :debug

  setup_all do
    {:ok, server} = :gen_udp.open 0, [:binary, {:active, false}]
    {:ok, port} = :inet.port(server)
    config [level: @level, metadata: @metadata, output: {:udp, "localhost", port}]
    on_exit fn ->
      :gen_udp.close(server)
    end
    {:ok, server: server}
  end

  test "sends debug message via UDP", %{server: server}do
    Logger.debug @message
    assert {:ok, {_ip, _port, message}} = :gen_udp.recv(server, 0, 500)
    assert {:ok, result} = JSON.decode(message)
    assert result["level"] == to_string(@level)
    assert result["message"] == @message
    assert result["metadata"] == @metadata
  end

  test "can change metadata", %{server: server} do
    new_metadata = "New metadata"
    config [metadata: new_metadata]
    Logger.debug @message
    assert {:ok, {_ip, _port, message}} = :gen_udp.recv(server, 0, 500)
    assert {:ok, result} = JSON.decode(message)
    assert result["level"] == to_string(@level)
    assert result["message"] == @message
    assert result["metadata"] == new_metadata
    config [metadata: @metadata]
  end

  test "can use info level", %{server: server} do
    config [level: :info]
    Logger.debug @message
    assert {:error, :timeout} = :gen_udp.recv(server, 0, 500)
    Logger.info @message
    assert {:ok, {_ip, _port, message}} = :gen_udp.recv(server, 0, 500)
    assert {:ok, result} = JSON.decode(message)
    assert result["level"] == "info"
    assert result["message"] == @message
    assert result["metadata"] == @metadata
    config [level: @level]
  end

  defp config(opts) do
    Logger.configure_backend(@backend, opts)
  end
  
end
