defmodule Sermo.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :username, :string
    field :password_hash, :string
    field :display_name, :string

    field :password, :string, virtual: true

    timestamps()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :display_name])
    |> validate_required([:username, :password])
    |> validate_length(:username, min: 2, max: 32)
    |> validate_length(:password, min: 6, max: 128)
    |> validate_length(:display_name, max: 64)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/, message: "must be alphanumeric")
    |> unique_constraint(:username)
    |> hash_password()
  end

  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(pass))

      _ ->
        changeset
    end
  end
end
