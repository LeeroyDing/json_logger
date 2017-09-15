defmodule Logger.Backends.JSON.TCPTest do
  use ExUnit.Case, async: false
  require Logger

  @backend {Logger.Backends.JSON, :test}

  @message "Yo"
  @level :debug

  setup_all do
    {:ok, server} = :gen_tcp.listen 0, [:binary, {:active, false}, {:packet, 0}, {:reuseaddr, true}]
    {:ok, port} = :inet.port server
    config [level: @level, output: {:tcp, "localhost", port}]
    on_exit fn ->
      :gen_tcp.close(server)
    end
    {:ok, server: server}
  end

  test "sends debug message via TCP", %{server: server} do
    Logger.debug @message
    assert {:ok, client} = :gen_tcp.accept(server, 500)
    assert {:ok, message} = :gen_tcp.recv(client, 0, 500)
    assert :ok = :gen_tcp.close(client)
    assert {:ok, result} = JSON.decode(message)
    assert result["level"] == to_string(@level)
    assert result["message"] == @message
  end

  defp config(opts) do
    Logger.configure_backend(@backend, opts)
  end
  
end
