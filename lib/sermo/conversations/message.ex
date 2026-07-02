defmodule Sermo.Conversations.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :body, :string
    belongs_to :conversation, Sermo.Conversations.Conversation
    belongs_to :sender, Sermo.Accounts.User

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body, :conversation_id, :sender_id])
    |> validate_required([:body, :conversation_id, :sender_id])
    |> validate_length(:body, min: 1, max: 4096)
  end
end
