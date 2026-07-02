defmodule Sermo.Conversations do
  import Ecto.Query, only: [from: 2]
  alias Sermo.Repo
  alias Sermo.Conversations.{Conversation, ConversationMember, Message}

  def create_direct_conversation(creator_id, other_user_id) do
    existing = find_direct_conversation(creator_id, other_user_id)

    if existing do
      {:ok, existing}
    else
      Repo.transaction(fn ->
        {:ok, conv} =
          %Conversation{}
          |> Conversation.changeset(%{type: "direct", created_by_id: creator_id})
          |> Repo.insert()

        Repo.insert!(%ConversationMember{
          user_id: creator_id,
          conversation_id: conv.id,
          role: "admin"
        })

        Repo.insert!(%ConversationMember{
          user_id: other_user_id,
          conversation_id: conv.id,
          role: "member"
        })

        conv
      end)
    end
  end

  def create_group_conversation(creator_id, name, member_ids) do
    Repo.transaction(fn ->
      {:ok, conv} =
        %Conversation{}
        |> Conversation.changeset(%{name: name, type: "group", created_by_id: creator_id})
        |> Repo.insert()

      Repo.insert!(%ConversationMember{
        user_id: creator_id,
        conversation_id: conv.id,
        role: "admin"
      })

      for member_id <- member_ids do
        Repo.insert!(%ConversationMember{
          user_id: member_id,
          conversation_id: conv.id,
          role: "member"
        })
      end

      conv
    end)
  end

  def list_conversations(user_id) do
    conversation_ids =
      Repo.all(
        from cm in ConversationMember,
          where: cm.user_id == ^user_id,
          select: cm.conversation_id
      )

    Repo.all(
      from c in Conversation,
        where: c.id in ^conversation_ids,
        order_by: [desc: c.updated_at]
    )
    |> Repo.preload(members: :user)
  end

  def send_message(conversation_id, sender_id, body) do
    %Message{}
    |> Message.changeset(%{body: body, conversation_id: conversation_id, sender_id: sender_id})
    |> Repo.insert()
    |> case do
      {:ok, msg} -> {:ok, Repo.preload(msg, :sender)}
      error -> error
    end
  end

  def list_messages(conversation_id, limit \\ 50) do
    Repo.all(
      from m in Message,
        where: m.conversation_id == ^conversation_id,
        order_by: [asc: m.inserted_at],
        limit: ^limit,
        preload: [:sender]
    )
  end

  defp find_direct_conversation(user1_id, user2_id) do
    user_ids = MapSet.new([user1_id, user2_id])

    Repo.all(
      from c in Conversation,
        where: c.type == "direct",
        preload: :members
    )
    |> Enum.find(fn conv ->
      member_ids = Enum.map(conv.members, & &1.user_id) |> MapSet.new()
      member_ids == user_ids
    end)
  end

  def list_members(conversation_id) do
    Repo.all(from cm in ConversationMember, where: cm.conversation_id == ^conversation_id)
  end

  def is_member?(user_id, conversation_id) do
    Repo.exists?(
      from cm in ConversationMember,
        where: cm.user_id == ^user_id and cm.conversation_id == ^conversation_id
    )
  end
end
