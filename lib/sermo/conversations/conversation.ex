defmodule Sermo.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversations" do
    field :name, :string
    field :type, :string, default: "direct"
    field :display_name, :string, virtual: true
    belongs_to :created_by, Sermo.Accounts.User
    has_many :members, Sermo.Conversations.ConversationMember
    has_many :messages, Sermo.Conversations.Message

    timestamps()
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:name, :type, :created_by_id])
    |> validate_required([:type, :created_by_id])
    |> validate_inclusion(:type, ~w(direct group))
  end
end
