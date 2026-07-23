defmodule Sermo.Conversations do
  @moduledoc """
  Conversations context module for managing conversations, members, and messages.
  """
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

  def get_conversation(id) do
    Repo.get(Conversation, id) |> Repo.preload(members: :user)
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

  def list_members(conversation_id) do
    Repo.all(
      from cm in ConversationMember,
        where: cm.conversation_id == ^conversation_id,
        preload: [:user]
    )
  end

  def member?(user_id, conversation_id) do
    Repo.exists?(
      from cm in ConversationMember,
        where: cm.user_id == ^user_id and cm.conversation_id == ^conversation_id
    )
  end

  def add_members(conversation_id, member_ids) do
    Repo.insert_all(
      ConversationMember,
      Enum.map(member_ids, fn user_id ->
        %{
          user_id: user_id,
          conversation_id: conversation_id,
          role: "member",
          inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
          updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
        }
      end)
    )
  end

  def remove_member(conversation_id, user_id) do
    {count, _} =
      Repo.delete_all(
        from cm in ConversationMember,
          where: cm.conversation_id == ^conversation_id and cm.user_id == ^user_id
      )

    count > 0
  end

  def delete_conversation(conversation_id) do
    Repo.delete_all(from m in Message, where: m.conversation_id == ^conversation_id)
    Repo.delete_all(from cm in ConversationMember, where: cm.conversation_id == ^conversation_id)
    Repo.delete_all(from c in Conversation, where: c.id == ^conversation_id)
    :ok
  end

  def send_message(conversation_id, sender_id, body) do
    %Message{}
    |> Message.changeset(%{body: body, conversation_id: conversation_id, sender_id: sender_id})
    |> Repo.insert()
    |> case do
      {:ok, msg} ->
        msg = Repo.preload(msg, :sender)
        broadcast_new_message(msg)
        touch_conversation(conversation_id)
        {:ok, msg}

      error ->
        error
    end
  end

  def update_message(message_id, sender_id, attrs) do
    case Repo.get(Message, message_id) do
      nil ->
        {:error, :not_found}

      message ->
        if message.sender_id == sender_id do
          apply_message_update(message, attrs)
        else
          {:error, :not_authorized}
        end
    end
  end

  def delete_message(message_id, sender_id) do
    case Repo.get(Message, message_id) do
      nil ->
        {:error, :not_found}

      message ->
        if message.sender_id == sender_id do
          Repo.delete!(message)
          broadcast_message_deleted(message)
          touch_conversation(message.conversation_id)
          {:ok, message}
        else
          {:error, :not_authorized}
        end
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

  def last_message(conversation_id) do
    Repo.one(
      from m in Message,
        where: m.conversation_id == ^conversation_id,
        order_by: [desc: m.inserted_at],
        limit: 1,
        preload: [:sender]
    )
  end

  def enrich_conversations(conversations, current_user_id) do
    Enum.map(conversations, fn conv ->
      display_name = get_display_name(conv, current_user_id)
      %{conv | display_name: display_name}
    end)
  end

  def broadcast_new_message(msg) do
    members = list_members(msg.conversation_id)

    for member <- members do
      Phoenix.PubSub.broadcast(
        Sermo.PubSub,
        "user:#{member.user_id}",
        {:new_message, msg}
      )
    end
  end

  def broadcast_message_updated(msg) do
    members = list_members(msg.conversation_id)

    for member <- members do
      Phoenix.PubSub.broadcast(
        Sermo.PubSub,
        "user:#{member.user_id}",
        {:message_updated, msg}
      )
    end
  end

  def broadcast_message_deleted(msg) do
    members = list_members(msg.conversation_id)

    for member <- members do
      Phoenix.PubSub.broadcast(
        Sermo.PubSub,
        "user:#{member.user_id}",
        {:message_deleted, msg.id, msg.conversation_id}
      )
    end
  end

  def broadcast_conversation_update(conv) do
    conv = if Ecto.assoc_loaded?(conv.members), do: conv, else: Repo.preload(conv, :members)

    for member <- conv.members do
      Phoenix.PubSub.broadcast(
        Sermo.PubSub,
        "user:#{member.user_id}",
        {:conversation_updated, conv.id}
      )
    end
  end

  def broadcast_member_removed(conversation_id, removed_user_id) do
    members = list_members(conversation_id)

    for member <- members do
      Phoenix.PubSub.broadcast(
        Sermo.PubSub,
        "user:#{member.user_id}",
        {:member_removed, conversation_id, removed_user_id}
      )
    end

    Phoenix.PubSub.broadcast(
      Sermo.PubSub,
      "user:#{removed_user_id}",
      {:you_were_removed, conversation_id}
    )
  end

  def broadcast_typing(conversation_id, user, member_ids) do
    for id <- member_ids do
      Phoenix.PubSub.broadcast(
        Sermo.PubSub,
        "user:#{id}",
        {:typing, conversation_id, user}
      )
    end
  end

  defp apply_message_update(message, attrs) do
    message
    |> Message.update_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, msg} ->
        msg = Repo.preload(msg, :sender)
        broadcast_message_updated(msg)
        touch_conversation(msg.conversation_id)
        {:ok, msg}

      error ->
        error
    end
  end

  defp get_display_name(conv, current_user_id) do
    if conv.type == "direct" do
      other = Enum.find(conv.members, fn m -> m.user_id != current_user_id end)
      if other && other.user, do: other.user.display_name || other.user.username, else: "Unknown"
    else
      conv.name || "Group"
    end
  end

  defp touch_conversation(conversation_id) do
    Repo.update_all(
      from(c in Conversation, where: c.id == ^conversation_id),
      set: [updated_at: DateTime.utc_now() |> DateTime.truncate(:second)]
    )
  end

  defp find_direct_conversation(user1_id, user2_id) do
    conversation_ids =
      from cm in ConversationMember,
        where: cm.user_id == ^user1_id or cm.user_id == ^user2_id,
        group_by: cm.conversation_id,
        having: count(cm.user_id) == 2,
        select: cm.conversation_id

    from(c in Conversation,
      where: c.type == "direct" and c.id in subquery(conversation_ids),
      preload: :members
    )
    |> Repo.one()
  end
end
