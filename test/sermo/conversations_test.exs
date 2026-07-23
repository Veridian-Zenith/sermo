defmodule Sermo.ConversationsTest do
  use Sermo.DataCase, async: true

  alias Sermo.Conversations
  import Sermo.Fixtures

  describe "create_direct_conversation/2" do
    test "creates a direct conversation between two users" do
      alice = create_user()
      bob = create_user()

      assert {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)
      assert conv.type == "direct"
      refute conv.name

      members = Conversations.list_members(conv.id)
      assert length(members) == 2
      assert Enum.find(members, fn m -> m.user_id == alice.id end)
      assert Enum.find(members, fn m -> m.user_id == bob.id end)
    end

    test "returns existing conversation instead of creating duplicate" do
      alice = create_user()
      bob = create_user()

      {:ok, conv1} = Conversations.create_direct_conversation(alice.id, bob.id)
      {:ok, conv2} = Conversations.create_direct_conversation(alice.id, bob.id)
      assert conv1.id == conv2.id
    end
  end

  describe "create_group_conversation/3" do
    test "creates a group conversation" do
      alice = create_user()
      bob = create_user()
      charlie = create_user()

      assert {:ok, conv} =
               Conversations.create_group_conversation(alice.id, "Dev Team", [
                 bob.id,
                 charlie.id
               ])

      assert conv.type == "group"
      assert conv.name == "Dev Team"

      members = Conversations.list_members(conv.id)
      assert length(members) == 3
    end
  end

  describe "list_conversations/1" do
    test "lists all conversations a user belongs to" do
      alice = create_user()
      bob = create_user()
      charlie = create_user()

      {:ok, _direct} = Conversations.create_direct_conversation(alice.id, bob.id)
      {:ok, _group} = Conversations.create_group_conversation(alice.id, "Group", [charlie.id])

      convs = Conversations.list_conversations(alice.id)
      assert length(convs) == 2

      convs = Conversations.list_conversations(bob.id)
      assert length(convs) == 1
    end
  end

  describe "send_message/3" do
    test "sends a message in a conversation" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)

      assert {:ok, msg} = Conversations.send_message(conv.id, alice.id, "Hello!")
      assert msg.body == "Hello!"
      assert msg.sender_id == alice.id
      assert msg.conversation_id == conv.id
    end

    test "validates message body" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)

      assert {:error, _} = Conversations.send_message(conv.id, alice.id, "")
      assert {:error, _} = Conversations.send_message(conv.id, alice.id, nil)
    end
  end

  describe "list_messages/1" do
    test "returns messages ordered by time" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)

      {:ok, m1} = Conversations.send_message(conv.id, alice.id, "First")
      {:ok, m2} = Conversations.send_message(conv.id, bob.id, "Second")

      messages = Conversations.list_messages(conv.id)
      assert length(messages) == 2
      assert List.first(messages).id == m1.id
      assert List.last(messages).id == m2.id
    end
  end

  describe "update_message/3" do
    test "allows sender to update their message" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)
      {:ok, msg} = Conversations.send_message(conv.id, alice.id, "Original")

      assert {:ok, updated} = Conversations.update_message(msg.id, alice.id, %{body: "Edited"})
      assert updated.body == "Edited"
    end

    test "prevents non-sender from updating" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)
      {:ok, msg} = Conversations.send_message(conv.id, alice.id, "Original")

      assert {:error, :not_authorized} =
               Conversations.update_message(msg.id, bob.id, %{body: "Hacked"})
    end

    test "validates body length" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)
      {:ok, msg} = Conversations.send_message(conv.id, alice.id, "Original")

      assert {:error, _} = Conversations.update_message(msg.id, alice.id, %{body: ""})
    end
  end

  describe "delete_message/2" do
    test "allows sender to delete their message" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)
      {:ok, _msg} = Conversations.send_message(conv.id, alice.id, "Delete me")

      messages = Conversations.list_messages(conv.id)
      assert length(messages) == 1

      Conversations.delete_message(hd(messages).id, alice.id)
      assert Conversations.list_messages(conv.id) == []
    end

    test "prevents non-sender from deleting" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)
      {:ok, msg} = Conversations.send_message(conv.id, alice.id, "Mine")

      assert {:error, :not_authorized} = Conversations.delete_message(msg.id, bob.id)
    end
  end

  describe "member?/2" do
    test "returns true for members" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)

      assert Conversations.member?(alice.id, conv.id)
      assert Conversations.member?(bob.id, conv.id)
    end

    test "returns false for non-members" do
      alice = create_user()
      bob = create_user()
      charlie = create_user(username: "charlie")
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)

      refute Conversations.member?(charlie.id, conv.id)
    end
  end

  describe "remove_member/2" do
    test "removes a user from a conversation" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)

      assert Conversations.member?(bob.id, conv.id)
      Conversations.remove_member(conv.id, bob.id)
      refute Conversations.member?(bob.id, conv.id)
    end
  end

  describe "delete_conversation/1" do
    test "deletes conversation and all related records" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)
      Conversations.send_message(conv.id, alice.id, "Message")

      Conversations.delete_conversation(conv.id)
      refute Conversations.get_conversation(conv.id)
    end
  end

  describe "enrich_conversations/2" do
    test "sets display name for direct conversations" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_direct_conversation(alice.id, bob.id)
      conv = Conversations.get_conversation(conv.id)

      enriched = Conversations.enrich_conversations([conv], alice.id)
      assert hd(enriched).display_name == bob.display_name
    end

    test "sets display name for group conversations" do
      alice = create_user()
      bob = create_user()
      {:ok, conv} = Conversations.create_group_conversation(alice.id, "Test Group", [bob.id])
      conv = Conversations.get_conversation(conv.id)

      enriched = Conversations.enrich_conversations([conv], alice.id)
      assert hd(enriched).display_name == "Test Group"
    end
  end
end
