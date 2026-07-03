defmodule SermoWeb.RegistrationController do
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
        {:ok, keys} = Accounts.generate_recovery_keys(user, 3)

        token =
          Phoenix.Token.sign(
            SermoWeb.Endpoint,
            "recovery-download",
            Enum.map_join(keys, "|", fn k -> "#{k.id}:#{k.key}" end)
          )

        conn
        |> SermoWeb.UserAuth.login(user)
        |> redirect(to: "/recovery-keys?token=#{token}")

      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)

        error_msg =
          Enum.map_join(errors, ", ", fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)

        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: "/register")
    end
  end
end
