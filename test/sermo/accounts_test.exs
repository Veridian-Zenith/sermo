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
end
