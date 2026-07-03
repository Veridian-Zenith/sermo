defmodule Sermo.Crypto do
  @moduledoc """
  Authenticated encryption using ChaCha20-Poly1305 via `:crypto`.

  Each encryption generates a random 12-byte nonce. The output is
  nonce ‖ ciphertext ‖ tag, base64-encoded for safe DB storage.

  The master encryption key (32 bytes) is read from application config
  under `:sermo, :recovery_encryption_key`.
  """

  @nonce_size 12
  @tag_size 16

  @doc """
  Encrypts `plaintext` (binary) and returns a base64-encoded ciphertext string.
  """
  def encrypt(plaintext) when is_binary(plaintext) do
    key = key()
    nonce = :crypto.strong_rand_bytes(@nonce_size)

    state = :crypto.crypto_one_time_aead_init(:chacha20_poly1305, key, @tag_size, true)
    cipher_with_tag = :crypto.crypto_one_time_aead(state, nonce, plaintext, "")

    <<nonce::binary-size(@nonce_size), cipher_with_tag::binary>>
    |> Base.encode64()
  end

  @doc """
  Decrypts a base64-encoded ciphertext string. Returns `{:ok, plaintext}` or `:error`.
  """
  def decrypt(encoded) when is_binary(encoded) do
    key = key()

    with {:ok, blob} <- Base.decode64(encoded),
         true <- byte_size(blob) > @nonce_size + @tag_size do
      <<nonce::binary-size(@nonce_size), cipher_with_tag::binary>> = blob

      state = :crypto.crypto_one_time_aead_init(:chacha20_poly1305, key, @tag_size, false)

      case :crypto.crypto_one_time_aead(state, nonce, cipher_with_tag, "") do
        plaintext when is_binary(plaintext) -> {:ok, plaintext}
        :error -> :error
      end
    else
      _ -> :error
    end
  end

  @doc """
  Generates a cryptographically random token of `bytes` length, returned as a
  hex-encoded string.
  """
  def random_token(bytes \\ 32) do
    :crypto.strong_rand_bytes(bytes)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Generates a human-friendly recovery key formatted as groups of hex characters
  separated by dashes, e.g. `a3f1-9c0b-47d2-e85a`.
  """
  def generate_recovery_key do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
    |> String.replace(~r/.{4}/, "\\0-")
    |> String.trim_trailing("-")
  end

  @doc """
  Hashes data using BLAKE2b-256. Use for internal integrity checks, NOT for
  password storage (use Argon2id for that).
  """
  def blake2b(data) when is_binary(data) do
    :crypto.hash(:blake2b, data)
    |> Base.encode16(case: :lower)
  end

  defp key do
    Application.fetch_env!(:sermo, :recovery_encryption_key)
  end
end
