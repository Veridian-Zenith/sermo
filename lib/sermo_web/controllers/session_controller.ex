defmodule SermoWeb.SessionController do
  use SermoWeb, :controller

  alias Sermo.Accounts

  def create(conn, %{"username" => username, "password" => password}) do
    case Accounts.authenticate(username, password) do
      {:ok, user} ->
        conn
        |> SermoWeb.UserAuth.login(user)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: "/chat")

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid username or password")
        |> redirect(to: "/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> SermoWeb.UserAuth.logout()
    |> redirect(to: "/login")
  end
end
