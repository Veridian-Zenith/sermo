defmodule Sermo.Accounts.Friendship do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "friendships" do
    belongs_to :requester, Sermo.Accounts.User
    belongs_to :requested, Sermo.Accounts.User
    field :status, :string, default: "pending"

    timestamps()
  end

  def changeset(friendship, attrs) do
    friendship
    |> cast(attrs, [:requester_id, :requested_id, :status])
    |> validate_required([:requester_id, :requested_id, :status])
    |> validate_inclusion(:status, ~w(pending accepted declined))
    |> unique_constraint([:requester_id, :requested_id])
  end
end
