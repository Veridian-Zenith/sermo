defmodule Sermo.Accounts do
  import Ecto.Query, only: [from: 2]

  alias Sermo.Repo
  alias Sermo.Accounts.User

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_username(username) do
    Repo.get_by(User, username: username)
  end

  def list_other_users(current_user_id) do
    Repo.all(
      from u in User,
        where: u.id != ^current_user_id,
        order_by: u.username
    )
  end

  def update_user(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  def change_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  def authenticate(username, password) do
    user = Repo.get_by(User, username: username)

    case user do
      nil ->
        {:error, :invalid_credentials}

      user ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end
end
