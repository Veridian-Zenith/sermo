defmodule Sermo.Fixtures do
  alias Sermo.Accounts
  alias Sermo.Conversations

  def unique_username, do: "user_#{System.unique_integer([:positive])}"

  def user_attrs(attrs \\ []) do
    defaults = [
      username: unique_username(),
      password: "password123",
      display_name: "Test User"
    ]

    Keyword.merge(defaults, attrs)
    |> Enum.into(%{})
  end

  def create_user(attrs \\ []) do
    {:ok, user} = Accounts.register_user(user_attrs(attrs))
    user
  end

  def direct_conversation(user1, user2) do
    {:ok, conv} = Conversations.create_direct_conversation(user1.id, user2.id)
    Conversations.get_conversation(conv.id)
  end

  def group_conversation(creator, members, name \\ "Test Group") do
    member_ids = Enum.map(members, & &1.id)
    {:ok, conv} = Conversations.create_group_conversation(creator.id, name, member_ids)
    Conversations.get_conversation(conv.id)
  end

  def send_message(conversation_id, sender, body \\ "Hello!") do
    {:ok, msg} = Conversations.send_message(conversation_id, sender.id, body)
    msg
  end
end
