defmodule Logger.Backends.JSON.UDPTest do
  use ExUnit.Case, async: false
  require Logger

  @backend {Logger.Backends.JSON, :test}
  Logger.add_backend @backend

  @message "Yo"
  @metadata "Very important data"
  @level :debug

  setup do
    Logger.add_backend @backend
    Logger.remove_backend :console
    {:ok, server} = :gen_udp.open(0)
    {:ok, port} = :inet.port(server)
    config [level: @level, metadata: @metadata, output: {:udp, "localhost", port}]
    on_exit fn ->
      :gen_udp.close(server)
    end
    {:ok, server: server}
  end
  
  test "sends debug message", %{server: server}do
    Logger.debug @message
    response_test = receive do
      {:udp, ^server, _ip, _port, message} ->
        assert {:ok, result} = JSON.decode(message)
        assert result["level"] == to_string(@level)
        assert result["message"] == @message
        assert result["metadata"] == @metadata
        {:ok}
      _ -> {:error, :nomatch}
      after 10000 -> {:error, :timeout}
    end
    assert response_test == {:ok}
  end

  test "can change metadata", %{server: server} do
    new_metadata = "New metadata"
    config [metadata: new_metadata]
    Logger.debug @message
    response_test = receive do
      {:udp, ^server, _ip, _port, message} ->
        assert {:ok, result} = JSON.decode(message)
        assert result["level"] == to_string(@level)
        assert result["message"] == @message
        assert result["metadata"] == new_metadata
        {:ok}
      _ -> {:error, :nomatch}
      after 1000 -> {:error, :timeout}
    end
    assert response_test == {:ok}
  end

  test "can modify log level", %{server: server} do
    config [level: :info]
    Logger.debug @message
    refute_receive {:udp, ^server, _ip, _port, _message}
    Logger.info @message
    response_test = receive do
      {:udp, ^server, _ip, _port, message} ->
        assert {:ok, result} = JSON.decode(message)
        assert result["level"] == "info"
        assert result["message"] == @message
        assert result["metadata"] == @metadata
        {:ok}
      _ -> {:error, :nomatch}
      after 1000 -> {:error, :timeout}
    end
    assert response_test == {:ok}
  end

  defp config(opts) do
    Logger.configure_backend(@backend, opts)
  end
  
end
