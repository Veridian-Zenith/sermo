defmodule Sermo.Accounts.RecoveryKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_recovery_keys" do
    belongs_to :user, Sermo.Accounts.User
    field :key_ciphertext, :string
    field :used_at, :utc_datetime

    timestamps()
  end

  def changeset(recovery_key, attrs) do
    recovery_key
    |> cast(attrs, [:user_id, :key_ciphertext, :used_at])
    |> validate_required([:user_id, :key_ciphertext])
  end
end
