defmodule Sermo.AccountsTest do
  use Sermo.DataCase, async: true

  alias Sermo.Accounts
  alias Sermo.Accounts.User
  import Sermo.Fixtures

  describe "register_user/1" do
    test "registers a user with valid attrs" do
      attrs = user_attrs()
      assert {:ok, %User{} = user} = Accounts.register_user(attrs)
      assert user.username == attrs.username
      assert user.display_name == attrs.display_name
      assert user.password_hash
    end

    test "validates username is required" do
      attrs = user_attrs(username: "")
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{username: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates username format" do
      attrs = user_attrs(username: "bad user!")
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{username: ["must be alphanumeric"]} = errors_on(changeset)
    end

    test "validates password length" do
      attrs = user_attrs(password: "12345")
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{password: ["should be at least 6 character(s)"]} = errors_on(changeset)
    end

    test "enforces unique username" do
      Accounts.register_user(user_attrs(username: "same"))
      attrs = user_attrs(username: "same", password: "different1")
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{username: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "get_user/1" do
    test "returns user by id" do
      user = create_user()
      assert Accounts.get_user(user.id).id == user.id
    end

    test "returns nil for non-existent id" do
      refute Accounts.get_user("00000000-0000-0000-0000-000000000000")
    end
  end

  describe "get_user_by_username/1" do
    test "finds user by username" do
      user = create_user()
      assert Accounts.get_user_by_username(user.username).id == user.id
    end

    test "returns nil for unknown username" do
      refute Accounts.get_user_by_username("nobody")
    end
  end

  describe "list_other_users/1" do
    test "returns all users except the given one" do
      user = create_user()
      other = create_user(username: "other_user")
      users = Accounts.list_other_users(user.id)
      assert length(users) == 1
      assert hd(users).id == other.id
    end
  end

  describe "update_user/2" do
    test "updates display name" do
      user = create_user()
      assert {:ok, updated} = Accounts.update_user(user, %{display_name: "New Name"})
      assert updated.display_name == "New Name"
    end

    test "validates display name length" do
      user = create_user()
      long = String.duplicate("a", 65)
      assert {:error, changeset} = Accounts.update_user(user, %{display_name: long})
      assert %{display_name: ["should be at most 64 character(s)"]} = errors_on(changeset)
    end

    test "allows nil display name" do
      user = create_user(display_name: "Original")
      assert {:ok, updated} = Accounts.update_user(user, %{display_name: nil})
      refute updated.display_name
    end
  end

  describe "change_password/2" do
    test "changes password successfully" do
      user = create_user()
      assert {:ok, _updated} = Accounts.change_password(user, %{password: "newpass123"})
      assert {:ok, _} = Accounts.authenticate(user.username, "newpass123")
    end

    test "validates minimum password length" do
      user = create_user()
      assert {:error, changeset} = Accounts.change_password(user, %{password: "short"})
      assert %{password: ["should be at least 6 character(s)"]} = errors_on(changeset)
    end
  end

  describe "authenticate/2" do
    test "authenticates with valid credentials" do
      user = create_user()
      assert {:ok, authed} = Accounts.authenticate(user.username, "password123")
      assert authed.id == user.id
    end

    test "fails with wrong password" do
      user = create_user()
      assert {:error, :invalid_credentials} = Accounts.authenticate(user.username, "wrongpass")
    end

    test "fails with unknown username" do
      assert {:error, :invalid_credentials} = Accounts.authenticate("nobody", "password123")
    end
  end

  describe "friendships" do
    test "send_friend_request/2 creates a pending request" do
      u1 = create_user()
      u2 = create_user()
      assert {:ok, f} = Accounts.send_friend_request(u1.id, u2.id)
      assert f.status == "pending"
      assert f.requester_id == u1.id
      assert f.requested_id == u2.id
    end

    test "send_friend_request/2 rejects duplicate requests" do
      u1 = create_user()
      u2 = create_user()
      Accounts.send_friend_request(u1.id, u2.id)
      assert {:error, :already_exists} = Accounts.send_friend_request(u1.id, u2.id)
    end

    test "send_friend_request/2 rejects reverse duplicate" do
      u1 = create_user()
      u2 = create_user()
      Accounts.send_friend_request(u1.id, u2.id)
      assert {:error, :already_exists} = Accounts.send_friend_request(u2.id, u1.id)
    end

    test "accept_friend_request/2 accepts a pending request" do
      u1 = create_user()
      u2 = create_user()
      {:ok, f} = Accounts.send_friend_request(u1.id, u2.id)
      assert {:ok, updated} = Accounts.accept_friend_request(f.id, u2.id)
      assert updated.status == "accepted"
    end

    test "accept_friend_request/2 rejects non-recipient" do
      u1 = create_user()
      u2 = create_user()
      u3 = create_user()
      {:ok, f} = Accounts.send_friend_request(u1.id, u2.id)
      assert {:error, :not_authorized} = Accounts.accept_friend_request(f.id, u3.id)
    end

    test "accept_friend_request/2 returns error for nonexistent" do
      assert {:error, :not_found} =
               Accounts.accept_friend_request(
                 "00000000-0000-0000-0000-000000000000",
                 "00000000-0000-0000-0000-000000000000"
               )
    end

    test "decline_friend_request/2 removes the request" do
      u1 = create_user()
      u2 = create_user()
      {:ok, f} = Accounts.send_friend_request(u1.id, u2.id)
      assert {:ok, :declined} = Accounts.decline_friend_request(f.id, u2.id)
      assert Accounts.friend_status(u1.id, u2.id) == :none
    end

    test "decline_friend_request/2 rejects non-recipient" do
      u1 = create_user()
      u2 = create_user()
      u3 = create_user()
      {:ok, f} = Accounts.send_friend_request(u1.id, u2.id)
      assert {:error, :not_authorized} = Accounts.decline_friend_request(f.id, u3.id)
    end

    test "cancel_friend_request/2 removes the request" do
      u1 = create_user()
      u2 = create_user()
      {:ok, f} = Accounts.send_friend_request(u1.id, u2.id)
      assert {:ok, :cancelled} = Accounts.cancel_friend_request(f.id, u1.id)
      assert Accounts.friend_status(u1.id, u2.id) == :none
    end

    test "cancel_friend_request/2 rejects non-requester" do
      u1 = create_user()
      u2 = create_user()
      u3 = create_user()
      {:ok, f} = Accounts.send_friend_request(u1.id, u2.id)
      assert {:error, :not_authorized} = Accounts.cancel_friend_request(f.id, u3.id)
    end

    test "remove_friend/2 removes accepted friendship" do
      u1 = create_user()
      u2 = create_user()
      {:ok, f} = Accounts.send_friend_request(u1.id, u2.id)
      Accounts.accept_friend_request(f.id, u2.id)
      assert {:ok, :removed} = Accounts.remove_friend(u1.id, u2.id)
      assert Accounts.friend_status(u1.id, u2.id) == :none
    end

    test "remove_friend/2 returns error for nonexistent" do
      u1 = create_user()
      u2 = create_user()
      assert {:error, :not_found} = Accounts.remove_friend(u1.id, u2.id)
    end

    test "friend_status/2 returns correct statuses" do
      u1 = create_user()
      u2 = create_user()

      assert Accounts.friend_status(u1.id, u2.id) == :none

      {:ok, f} = Accounts.send_friend_request(u1.id, u2.id)
      assert Accounts.friend_status(u1.id, u2.id) == :pending_sent
      assert Accounts.friend_status(u2.id, u1.id) == :pending_received

      Accounts.accept_friend_request(f.id, u2.id)
      assert Accounts.friend_status(u1.id, u2.id) == :friends
      assert Accounts.friend_status(u2.id, u1.id) == :friends
    end

    test "list_friends/1 returns accepted friends" do
      u1 = create_user()
      u2 = create_user()
      u3 = create_user()
      {:ok, f} = Accounts.send_friend_request(u1.id, u2.id)
      Accounts.accept_friend_request(f.id, u2.id)

      friends = Accounts.list_friends(u1.id)
      assert length(friends) == 1
      assert hd(friends).id == u2.id

      assert Accounts.list_friends(u3.id) == []
    end

    test "list_incoming_requests/1 returns pending requests to user" do
      u1 = create_user()
      u2 = create_user()
      Accounts.send_friend_request(u1.id, u2.id)

      incoming = Accounts.list_incoming_requests(u2.id)
      assert length(incoming) == 1
      assert hd(incoming).requester_id == u1.id

      assert Accounts.list_incoming_requests(u1.id) == []
    end

    test "list_outgoing_requests/1 returns pending requests from user" do
      u1 = create_user()
      u2 = create_user()
      Accounts.send_friend_request(u1.id, u2.id)

      outgoing = Accounts.list_outgoing_requests(u1.id)
      assert length(outgoing) == 1
      assert hd(outgoing).requested_id == u2.id

      assert Accounts.list_outgoing_requests(u2.id) == []
    end
  end

  describe "recovery keys" do
    test "generate_recovery_keys/2 creates the given number of keys" do
      user = create_user()
      assert {:ok, keys} = Accounts.generate_recovery_keys(user, 3)
      assert length(keys) == 3

      for k <- keys do
        assert k.id
        assert byte_size(k.key) > 0
        assert k.used_at == nil
      end
    end

    test "list_recovery_keys/1 returns key metadata" do
      user = create_user()
      {:ok, _keys} = Accounts.generate_recovery_keys(user, 2)
      listed = Accounts.list_recovery_keys(user)
      assert length(listed) == 2

      for k <- listed do
        assert Map.has_key?(k, :id)
        assert Map.has_key?(k, :used)
        refute Map.has_key?(k, :key)
      end
    end

    test "recover_account/3 changes password with valid key" do
      user = create_user()
      {:ok, keys} = Accounts.generate_recovery_keys(user, 1)
      key = hd(keys)

      assert {:ok, _updated} = Accounts.recover_account(user.username, key.key, "newpassword1")
      assert {:ok, _} = Accounts.authenticate(user.username, "newpassword1")
      assert {:error, :invalid_credentials} = Accounts.authenticate(user.username, "password123")
    end

    test "recover_account/3 marks key as used" do
      user = create_user()
      {:ok, [key]} = Accounts.generate_recovery_keys(user, 1)
      Accounts.recover_account(user.username, key.key, "newpassword1")
      refute Accounts.has_recovery_keys?(user)
    end

    test "recover_account/3 fails with wrong key" do
      user = create_user()
      Accounts.generate_recovery_keys(user, 1)

      assert {:error, :invalid_recovery_key} =
               Accounts.recover_account(user.username, "wrong-key", "newpassword1")
    end

    test "recover_account/3 fails with unknown username" do
      assert {:error, :invalid_username} =
               Accounts.recover_account("nobody", "some-key", "newpassword1")
    end

    test "has_recovery_keys?/1 returns true when keys exist" do
      user = create_user()
      refute Accounts.has_recovery_keys?(user)
      Accounts.generate_recovery_keys(user, 1)
      assert Accounts.has_recovery_keys?(user)
    end
  end
end
