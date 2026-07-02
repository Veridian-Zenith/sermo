defmodule Sermo.Conversations.ConversationMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversation_members" do
    belongs_to :user, Sermo.Accounts.User
    belongs_to :conversation, Sermo.Conversations.Conversation
    field :role, :string, default: "member"

    timestamps()
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:user_id, :conversation_id, :role])
    |> validate_required([:user_id, :conversation_id])
    |> validate_inclusion(:role, ~w(admin member))
    |> unique_constraint([:user_id, :conversation_id])
  end
end
