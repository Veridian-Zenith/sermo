defmodule SermoWeb.Plugs.RateLimit do
  @moduledoc """
  Plug for rate limiting requests by IP address.
  """
  import Plug.Conn

  @table :sermo_rate_limit
  @window_ms 60_000
  @max_requests 20

  def init(opts), do: opts

  def call(conn, opts) do
    max = opts[:max] || Application.get_env(:sermo, __MODULE__, [])[:max] || @max_requests
    ip = conn.remote_ip |> :inet.ntoa() |> List.to_string()
    key = {:auth, ip, window_slot()}
    count = incr(key)

    if count > max do
      conn
      |> put_resp_header("retry-after", "60")
      |> send_resp(429, "Too Many Requests")
      |> halt()
    else
      conn
    end
  end

  defp window_slot, do: div(:os.system_time(:millisecond), @window_ms)

  defp incr(key) do
    tid = table()

    try do
      case :ets.insert_new(tid, {key, 1}) do
        true -> 1
        false -> :ets.update_counter(tid, key, {2, 1})
      end
    catch
      :error, _ -> 0
    end
  end

  defp table do
    case :ets.info(@table) do
      :undefined ->
        try do
          :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
        rescue
          ArgumentError -> @table
        end

      _ ->
        @table
    end
  end
end
