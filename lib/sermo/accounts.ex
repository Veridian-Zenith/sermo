defmodule Sermo.Accounts do
  @moduledoc """
  Accounts context for user management, authentication, and friendships.
  """
  import Ecto.Query, only: [from: 2]

  alias Sermo.Repo
  alias Sermo.Accounts.User
  alias Sermo.Accounts.Friendship
  alias Sermo.Accounts.RecoveryKey
  alias Sermo.Crypto

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_username(username) do
    Repo.get_by(User, username: username)
  end

  def list_other_users(current_user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)

    Repo.all(
      from u in User,
        where: u.id != ^current_user_id,
        order_by: u.username,
        limit: ^limit,
        offset: ^offset
    )
  end

  def update_user(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  def change_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  def authenticate(username, password) do
    user = Repo.get_by(User, username: username)

    case user do
      nil ->
        {:error, :invalid_credentials}

      user ->
        if Argon2.verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  def generate_recovery_keys(user, count \\ 3) do
    keys_with_plaintext =
      Enum.map(1..count, fn _ ->
        plain = Crypto.generate_recovery_key()
        encrypted = Crypto.encrypt(plain)

        %{plain: plain, encrypted: encrypted}
      end)

    {:ok, records} =
      Repo.transaction(fn ->
        Enum.map(keys_with_plaintext, fn k ->
          %RecoveryKey{}
          |> RecoveryKey.changeset(%{
            user_id: user.id,
            key_ciphertext: k.encrypted
          })
          |> Repo.insert!()
        end)
      end)

    plaintexts =
      keys_with_plaintext
      |> Enum.zip(records)
      |> Enum.map(fn {k, rec} -> %{id: rec.id, key: k.plain, used_at: nil} end)

    {:ok, plaintexts}
  end

  def list_recovery_keys(user) do
    Repo.all(
      from r in RecoveryKey,
        where: r.user_id == ^user.id,
        order_by: [asc: r.inserted_at]
    )
    |> Enum.map(fn r ->
      %{
        id: r.id,
        used: r.used_at != nil,
        used_at: r.used_at,
        inserted_at: r.inserted_at
      }
    end)
  end

  def recover_account(username, recovery_key, new_password) do
    with %User{} = user <- Repo.get_by(User, username: username),
         {:ok, key_id} <- verify_recovery_key(user, recovery_key) do
      mark_key_used(key_id)

      user
      |> User.password_changeset(%{password: new_password})
      |> Repo.update()
    else
      nil -> {:error, :invalid_username}
      :not_found -> {:error, :invalid_recovery_key}
      {:error, :invalid_recovery_key} -> {:error, :invalid_recovery_key}
      {:error, _} -> {:error, :recovery_failed}
    end
  end

  def has_recovery_keys?(user) do
    count =
      Repo.aggregate(
        from(r in RecoveryKey, where: r.user_id == ^user.id and is_nil(r.used_at)),
        :count,
        :id
      )

    count > 0
  end

  defp verify_recovery_key(user, plaintext_key) do
    keys =
      Repo.all(
        from r in RecoveryKey,
          where: r.user_id == ^user.id and is_nil(r.used_at)
      )

    matched =
      Enum.find_value(keys, fn key_record ->
        case Crypto.decrypt(key_record.key_ciphertext) do
          {:ok, ^plaintext_key} -> key_record.id
          _ -> false
        end
      end)

    case matched do
      nil -> {:error, :invalid_recovery_key}
      id -> {:ok, id}
    end
  end

  defp mark_key_used(key_id) do
    now = DateTime.utc_now()

    Repo.get!(RecoveryKey, key_id)
    |> RecoveryKey.changeset(%{used_at: now})
    |> Repo.update!()
  end

  def send_friend_request(requester_id, requested_id) do
    case friend_status(requester_id, requested_id) do
      :none ->
        %Friendship{}
        |> Friendship.changeset(%{
          requester_id: requester_id,
          requested_id: requested_id,
          status: "pending"
        })
        |> Repo.insert()

      _ ->
        {:error, :already_exists}
    end
  end

  def accept_friend_request(friendship_id, user_id) do
    case Repo.get(Friendship, friendship_id) do
      nil ->
        {:error, :not_found}

      %Friendship{requested_id: ^user_id, status: "pending"} = f ->
        f
        |> Friendship.changeset(%{status: "accepted"})
        |> Repo.update()

      _ ->
        {:error, :not_authorized}
    end
  end

  def decline_friend_request(friendship_id, user_id) do
    case Repo.get(Friendship, friendship_id) do
      nil ->
        {:error, :not_found}

      %Friendship{requested_id: ^user_id, status: "pending"} = f ->
        Repo.delete!(f)
        {:ok, :declined}

      _ ->
        {:error, :not_authorized}
    end
  end

  def cancel_friend_request(friendship_id, user_id) do
    case Repo.get(Friendship, friendship_id) do
      nil ->
        {:error, :not_found}

      %Friendship{requester_id: ^user_id, status: "pending"} = f ->
        Repo.delete!(f)
        {:ok, :cancelled}

      _ ->
        {:error, :not_authorized}
    end
  end

  def remove_friend(user_id, friend_id) do
    friendship = find_friendship(user_id, friend_id)

    case friendship do
      nil ->
        {:error, :not_found}

      _ ->
        Repo.delete!(friendship)
        {:ok, :removed}
    end
  end

  def list_friends(user_id) do
    accepted =
      Repo.all(
        from f in Friendship,
          where:
            (f.requester_id == ^user_id or f.requested_id == ^user_id) and f.status == "accepted",
          preload: [:requester, :requested]
      )

    Enum.map(accepted, fn f ->
      if f.requester_id == user_id, do: f.requested, else: f.requester
    end)
  end

  def list_incoming_requests(user_id) do
    Repo.all(
      from f in Friendship,
        where: f.requested_id == ^user_id and f.status == "pending",
        preload: [:requester]
    )
  end

  def list_outgoing_requests(user_id) do
    Repo.all(
      from f in Friendship,
        where: f.requester_id == ^user_id and f.status == "pending",
        preload: [:requested]
    )
  end

  def friend_status(user_id, other_id) do
    case find_friendship(user_id, other_id) do
      nil ->
        :none

      %Friendship{status: "pending", requester_id: ^other_id} ->
        :pending_received

      %Friendship{status: "pending"} ->
        :pending_sent

      %Friendship{status: "accepted"} ->
        :friends

      _ ->
        :none
    end
  end

  defp find_friendship(user1_id, user2_id) do
    Repo.one(
      from f in Friendship,
        where:
          (f.requester_id == ^user1_id and f.requested_id == ^user2_id) or
            (f.requester_id == ^user2_id and f.requested_id == ^user1_id)
    )
  end
end
