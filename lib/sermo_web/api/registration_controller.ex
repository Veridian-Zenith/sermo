defmodule SermoWeb.API.RegistrationController do
  use SermoWeb, :controller

  alias Sermo.Accounts

  def create(conn, params) do
    username = params["username"]
    password = params["password"]
    display_name = if (params["display_name"] || "") == "", do: nil, else: params["display_name"]

    case Accounts.register_user(%{
           username: username,
           password: password,
           display_name: display_name
         }) do
      {:ok, user} ->
        token = SermoWeb.API.Auth.generate_token(user)

        conn
        |> put_status(:created)
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

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors})
    end
  end
end
