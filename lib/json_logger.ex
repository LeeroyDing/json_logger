defmodule Logger.Backends.JSON do
  use GenEvent

  def init(_) do
    if user = Process.whereis(:user) do
      Process.group_leader(self(), user)
      {:ok, configure([])}
    else
      {:error, :ignore}
    end
  end

  def handle_call({:configure, options}, _state) do
    {:ok, :ok, configure(options)}
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

  ## Helpers

  defp configure(options) do
    json_logger = Keyword.merge(Application.get_env(:logger, :json_logger, []), options)
    Application.put_env(:logger, :json_logger, json_logger)

    level    = Keyword.get(json_logger, :level)
    metadata = Keyword.get(json_logger, :metadata, [])
    output   = Keyword.get(json_logger, :output, :console)
    output = case output do
               :console -> :console
               {:udp, host, port} ->
                 {:ok, socket} = :gen_udp.open 0
                 {:udp, host, port, socket}
             end
    %{metadata: metadata, level: level, output: output}
  end

  defp log_event(level, msg, ts, md, %{metadata: metadata, output: :console}) do
    IO.puts event_json(level, msg, ts, md, metadata)
  end

  defp log_event(level, msg, ts, md, %{metadata: metadata, output: {:udp, host, port, socket}}) do
    json = event_json(level, msg, ts, md, metadata)
    host = host |> to_char_list
    :gen_udp.send socket, host, port, [json]
  end

  defp event_json(level, msg, _ts, [pid: pid, module: module, function: function, line: line], metadata) do
    pid_str = :io_lib.fwrite('~p', [pid]) |> to_string
    JSON.encode! %{level: level, msg: msg, pid: pid_str, module: module, function: function, line: line, metadata: metadata}
  end
end
