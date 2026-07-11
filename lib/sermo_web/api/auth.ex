defmodule SermoWeb.API.Auth do
  import Plug.Conn

  @token_salt "api-auth-token"

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> fetch_headers()
    |> authenticate()
  end

  defp fetch_headers(conn) do
    case get_req_header(conn, "authorization") do
      [token] -> assign(conn, :raw_token, String.replace_prefix(token, "Bearer ", ""))
      _ -> assign(conn, :raw_token, nil)
    end
  end

  defp authenticate(%{assigns: %{raw_token: nil}} = conn), do: assign(conn, :api_user, nil)

  defp authenticate(conn) do
    case Phoenix.Token.verify(SermoWeb.Endpoint, @token_salt, conn.assigns.raw_token,
           max_age: 86_400 * 30
         ) do
      {:ok, user_id} ->
        assign(conn, :api_user, Sermo.Accounts.get_user(user_id))

      {:error, _} ->
        assign(conn, :api_user, nil)
    end
  end

  def generate_token(user) do
    Phoenix.Token.sign(SermoWeb.Endpoint, @token_salt, user.id)
  end

  def require_auth(conn, _opts) do
    if Map.get(conn.assigns, :api_user) do
      conn
    else
      conn
      |> put_resp_header("content-type", "application/json; charset=utf-8")
      |> send_resp(401, Jason.encode!(%{errors: %{detail: "Unauthorized"}}))
      |> halt()
    end
  end
end
