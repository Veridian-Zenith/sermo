defmodule SermoWeb.Plugs.RateLimitTest do
  use SermoWeb.ConnCase, async: false

  setup do
    case :ets.info(:sermo_rate_limit) do
      :undefined ->
        :ets.new(:sermo_rate_limit, [:named_table, :public, :set, write_concurrency: true])

      _ ->
        :ok
    end

    on_exit(fn ->
      case :ets.info(:sermo_rate_limit) do
        :undefined -> :ok
        _ -> :ets.delete(:sermo_rate_limit)
      end
    end)

    :ok
  end

  test "allows requests under the limit", %{conn: conn} do
    conn =
      conn
      |> SermoWeb.Plugs.RateLimit.call(%{})

    refute conn.halted
  end

  test "halts when over the limit", %{conn: conn} do
    opts = [max: 3]
    conn = %{conn | remote_ip: {192, 168, 1, 1}}

    conn =
      Enum.reduce(1..3, conn, fn _conn, acc ->
        SermoWeb.Plugs.RateLimit.call(acc, opts)
      end)

    conn = SermoWeb.Plugs.RateLimit.call(conn, opts)
    assert conn.halted
    assert conn.status == 429
  end

  test "uses separate counters per IP", %{conn: conn} do
    opts = [max: 2]

    conn_a = SermoWeb.Plugs.RateLimit.call(%{conn | remote_ip: {10, 0, 0, 1}}, opts)
    refute conn_a.halted

    conn_a = SermoWeb.Plugs.RateLimit.call(%{conn | remote_ip: {10, 0, 0, 1}}, opts)
    refute conn_a.halted

    conn_a = SermoWeb.Plugs.RateLimit.call(%{conn | remote_ip: {10, 0, 0, 1}}, opts)
    assert conn_a.halted

    conn_b = SermoWeb.Plugs.RateLimit.call(%{conn | remote_ip: {10, 0, 0, 2}}, opts)
    refute conn_b.halted
  end
end
