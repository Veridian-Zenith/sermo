defmodule SermoWeb.API.SessionController do
  use SermoWeb, :controller

  alias Sermo.Accounts

  def create(conn, %{"username" => username, "password" => password}) do
    case Accounts.authenticate(username, password) do
      {:ok, user} ->
        token = SermoWeb.API.Auth.generate_token(user)

        conn
        |> json(%{
          data: %{
            token: token,
            user: %{
              id: user.id,
              username: user.username,
              display_name: user.display_name
            }
          }
        })

      {:error, _} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: %{detail: "Invalid credentials"}})
    end
  end

  def delete(conn, _params) do
    json(conn, %{data: %{message: "Session ended"}})
  end
end
