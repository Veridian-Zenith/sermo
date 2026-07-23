defmodule Sermo.Crypto do
  @moduledoc """
  Authenticated encryption using AES-256-CTR + HMAC-SHA256 (Encrypt-then-MAC).

  CTR mode requires no padding. Each encryption generates a random 16-byte nonce.
  The output is: nonce ‖ ciphertext ‖ HMAC, base64-encoded for safe DB storage.

  The master key (32 bytes) is read from application config
  under `:sermo, :recovery_encryption_key`.
  """

  @nonce_size 16
  @tag_size 32

  @doc """
  Encrypts `plaintext` (binary) and returns a base64-encoded ciphertext string.
  """
  def encrypt(plaintext) when is_binary(plaintext) do
    master_key = key()
    nonce = :crypto.strong_rand_bytes(@nonce_size)

    # Derive encryption and MAC keys using HKDF
    {enc_key, mac_key} = derive_keys(master_key, nonce)

    # Encrypt with AES-256-CTR (no padding needed)
    ciphertext = aes_ctr_encrypt(enc_key, nonce, plaintext)

    # Compute HMAC-SHA256 of nonce || ciphertext (Encrypt-then-MAC)
    mac_data = <<nonce::binary, ciphertext::binary>>
    tag = :crypto.mac(:hmac, :sha256, mac_key, mac_data)

    <<nonce::binary, ciphertext::binary, tag::binary>>
    |> Base.encode64()
  end

  @doc """
  Decrypts a base64-encoded ciphertext string. Returns `{:ok, plaintext}` or `:error`.
  """
  def decrypt(encoded) when is_binary(encoded) do
    master_key = key()

    with {:ok, blob} <- Base.decode64(encoded),
         true <- byte_size(blob) >= @nonce_size + @tag_size do
      ciphertext_len = byte_size(blob) - @nonce_size - @tag_size

      <<nonce::binary-size(@nonce_size), ciphertext::binary-size(^ciphertext_len),
        tag::binary-size(@tag_size)>> = blob

      {enc_key, mac_key} = derive_keys(master_key, nonce)

      # Verify HMAC first (constant-time comparison)
      mac_data = <<nonce::binary, ciphertext::binary>>
      expected_tag = :crypto.mac(:hmac, :sha256, mac_key, mac_data)

      if secure_compare(tag, expected_tag) do
        # Decrypt
        {:ok, plaintext} = aes_ctr_decrypt(enc_key, nonce, ciphertext)
        {:ok, plaintext}
      else
        :error
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

  defp derive_keys(master_key, nonce) do
    # Use HKDF to derive two 32-byte keys from master_key
    salt = nonce
    info_enc = "sermo-encryption-v1"
    info_mac = "sermo-mac-v1"

    prk = :crypto.mac(:hmac, :sha256, master_key, salt)
    enc_key = hkdf_expand(prk, info_enc, 32)
    mac_key = hkdf_expand(prk, info_mac, 32)

    {enc_key, mac_key}
  end

  defp hkdf_expand(prk, info, length) do
    # HKDF-Expand as per RFC 5869
    # ceil(length / 32)
    n = div(length + 31, 32)

    blocks =
      for i <- 1..n, reduce: <<>> do
        acc ->
          input = <<acc::binary, info::binary, i::8>>
          t = :crypto.mac(:hmac, :sha256, prk, input)
          <<acc::binary, t::binary>>
      end

    binary_part(blocks, 0, length)
  end

  defp aes_ctr_encrypt(key, nonce, plaintext) do
    # AES-256-CTR uses the nonce as the initial counter value
    # nonce is 16 bytes, used directly as IV
    :crypto.crypto_one_time(:aes_256_ctr, key, nonce, plaintext, true)
  end

  defp aes_ctr_decrypt(key, nonce, ciphertext) do
    # CTR decryption is identical to encryption
    plaintext = :crypto.crypto_one_time(:aes_256_ctr, key, nonce, ciphertext, false)
    {:ok, plaintext}
  end

  defp secure_compare(a, b) when is_binary(a) and is_binary(b) and byte_size(a) == byte_size(b) do
    # Constant-time comparison using HMAC
    :crypto.mac(:hmac, :sha256, a, b) == :crypto.mac(:hmac, :sha256, b, a)
  end

  defp secure_compare(_, _), do: false

  defp key do
    Application.fetch_env!(:sermo, :recovery_encryption_key)
  end
end
