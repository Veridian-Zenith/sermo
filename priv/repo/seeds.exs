alias Sermo.Repo
alias Sermo.Accounts.User
alias Sermo.Conversations.{Conversation, ConversationMember, Message}

import Ecto.Query, only: [from: 2]

seed_users = [
  %{username: "alice", password: "password123", display_name: "Alice"},
  %{username: "bob", password: "password123", display_name: "Bob"},
  %{username: "charlie", password: "password123", display_name: "Charlie"},
  %{username: "diana", password: "password123", display_name: "Diana"}
]

inserted_users =
  Enum.map(seed_users, fn attrs ->
    case Repo.get_by(User, username: attrs.username) do
      nil ->
        {:ok, user} =
          %User{}
          |> User.registration_changeset(attrs)
          |> Repo.insert()

        user

      user ->
        user
    end
  end)

[alice, bob, charlie, _diana] = inserted_users

if !Repo.one(from c in Conversation, where: c.type == "direct", limit: 1) do
  {:ok, direct} =
    Repo.transaction(fn ->
      {:ok, conv} =
        %Conversation{}
        |> Conversation.changeset(%{type: "direct", created_by_id: alice.id})
        |> Repo.insert()

      Repo.insert!(%ConversationMember{
        user_id: alice.id,
        conversation_id: conv.id,
        role: "admin"
      })

      Repo.insert!(%ConversationMember{
        user_id: bob.id,
        conversation_id: conv.id,
        role: "member"
      })

      conv
    end)

  messages_direct = [
    %{body: "Hey Bob! How's the project going?", sender_id: alice.id},
    %{body: "Going well! Almost done with the API refactor.", sender_id: bob.id},
    %{body: "Great to hear! Let me know if you need any help.", sender_id: alice.id},
    %{body: "Will do. Thanks Alice!", sender_id: bob.id}
  ]

  Enum.each(messages_direct, fn attrs ->
    %Message{}
    |> Message.changeset(Map.put(attrs, :conversation_id, direct.id))
    |> Repo.insert!()
  end)
end

if !Repo.one(from c in Conversation, where: c.type == "group", limit: 1) do
  {:ok, group} =
    Repo.transaction(fn ->
      {:ok, conv} =
        %Conversation{}
        |> Conversation.changeset(%{
          name: "Dev Team",
          type: "group",
          created_by_id: alice.id
        })
        |> Repo.insert()

      [alice, bob, charlie]
      |> Enum.each(fn u ->
        Repo.insert!(%ConversationMember{
          user_id: u.id,
          conversation_id: conv.id,
          role: if(u.id == alice.id, do: "admin", else: "member")
        })
      end)

      conv
    end)

  messages_group = [
    %{body: "Welcome to the Dev Team channel!", sender_id: alice.id},
    %{body: "Hey everyone! 👋", sender_id: bob.id},
    %{body: "Hi folks! Excited to be here.", sender_id: charlie.id},
    %{body: "Let's start planning the beta release.", sender_id: alice.id},
    %{body: "I'll prepare a timeline and share it here.", sender_id: bob.id}
  ]

  Enum.each(messages_group, fn attrs ->
    %Message{}
    |> Message.changeset(Map.put(attrs, :conversation_id, group.id))
    |> Repo.insert!()
  end)
end

IO.puts("Seeds OK — #{length(inserted_users)} users present")
