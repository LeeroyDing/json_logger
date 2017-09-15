defmodule Logger.Backends.JSON do
  alias Logger.Backends.JSON.TCPClient
  use GenEvent

  def init(_) do
    if user = Process.whereis(:user) do
      Process.group_leader(self(), user)
      {:ok, configure([])}
    else
      {:error, :ignore}
    end
  end

  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(options, state)}
  end

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, %{level: min_level} = state) do
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      log_event(level, msg, ts, md, state)
    end
    {:ok, state}
  end

  def terminate(_reason, %{output: {:udp, _host, _port, socket}}) do
    :gen_udp.close(socket)
    :ok
  end

  def terminate(_reason, %{output: {:tcp, client}}) do
    TCPClient.stop client
    :ok
  end

  ## Helpers

  defp configure(options, %{output: {:udp, _host, _port, socket}}) do
    :gen_udp.close(socket)
    configure(options)
  end

  defp configure(options, %{output: {:tcp, client}}) do
    TCPClient.stop client
    configure(options)
  end

  defp configure(options, _state) do
    configure(options)
  end

  defp configure(options) do
    json_logger = Keyword.merge(Application.get_env(:logger, :json_logger, []), options)
    Application.put_env(:logger, :json_logger, json_logger)

    level    = Keyword.get(json_logger, :level)
    output   = Keyword.get(json_logger, :output, :console)
    output = case output do
               :console -> :console
               {:udp, host, port} ->
                 {:ok, socket} = :gen_udp.open 0
                 host = host |> to_char_list
                 {:udp, host, port, socket}
               {:tcp, host, port} ->
                 host = host |> to_char_list
                 {:ok, tcp_client} = TCPClient.start_link(host, port)
                 {:tcp, tcp_client}
             end
    %{level: level, output: output}
  end

  defp log_event(level, msg, ts, md, %{output: :console}) do
    IO.puts event_json(level, msg, ts, md)
  end

  defp log_event(level, msg, ts, md, %{output: {:udp, host, port, socket}}) do
    json = event_json(level, msg, ts, md)
    :gen_udp.send socket, host, port, [json]
  end

  defp log_event(level, msg, ts, md, %{output: {:tcp, client}}) do
    json = event_json(level, msg, ts, md)
    TCPClient.log_msg client, json
  end

  defp event_json(level, msg, _ts, md) do
    pid_str = :io_lib.fwrite('~p', [md[:pid]]) |> to_string

    %{level: level, message: msg, pid: pid_str}
    |> Map.merge(md |> Enum.map(&stringify_values/1) |> Enum.into(Map.new))
    |> JSON.encode!
  end

  defp stringify_values({k, v}) when is_binary(v), do: {k, v}
  defp stringify_values({k, v}), do: {k, inspect(v)}
end
