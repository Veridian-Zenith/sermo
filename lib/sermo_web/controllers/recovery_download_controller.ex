defmodule SermoWeb.RecoveryDownloadController do
  use SermoWeb, :controller

  alias Sermo.Accounts

  def download(conn, %{"token" => token}) do
    session_user_id = get_session(conn, :user_id)

    user = session_user_id && Accounts.get_user(session_user_id)

    with {:user, %{username: username}} when not is_nil(user) <- {:user, user},
         {:ok, data} <-
           Phoenix.Token.verify(SermoWeb.Endpoint, "recovery-download", token, max_age: 86_400),
         keys when is_list(keys) and keys != [] <- decode_keys(data) do
      content = build_txt(username, keys)

      conn
      |> put_resp_content_type("text/plain", "utf-8")
      |> put_resp_header(
        "content-disposition",
        "attachment; filename=\"sermo-recovery-keys.txt\""
      )
      |> send_resp(200, content)
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> put_resp_content_type("text/html")
        |> send_resp(404, "<h1>Not Found</h1>")
    end
  end

  def download(conn, _) do
    conn
    |> put_status(:not_found)
    |> put_resp_content_type("text/html")
    |> send_resp(404, "<h1>Not Found</h1>")
  end

  defp decode_keys(data) when is_binary(data) do
    parts = String.split(data, "|")

    Enum.map(parts, fn part ->
      case String.split(part, ":", parts: 2) do
        [_, key] -> %{key: key}
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp decode_keys(_), do: []

  defp build_txt(username, keys) do
    """
    ╔══════════════════════════════════════════╗
    ║         SERMO — Account Recovery Keys    ║
    ║  Save this file somewhere safe.          ║
    ║  Each key can be used ONCE to reset      ║
    ║  your password.                          ║
    ╚══════════════════════════════════════════╝

    Account: #{username}

    Recovery Keys:
    #{Enum.map_join(keys, "\n", fn k -> "  #{k.key}" end)}

    ────────────────────────────────────────────
    Generated: #{NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second) |> to_string()}
    """
  end
end
