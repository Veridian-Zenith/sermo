defmodule SermoWeb.Plugs.SecurityHeaders do
  @moduledoc """
  Plug for setting security-related HTTP response headers.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("x-frame-options", "DENY")
    |> put_resp_header("x-xss-protection", "0")
    |> put_resp_header("referrer-policy", "strict-origin-when-cross-origin")
    |> put_resp_header(
      "content-security-policy",
      "default-src 'self'; " <>
        "style-src 'self' 'unsafe-inline'; " <>
        "font-src 'self'; " <>
        "img-src 'self' data:; " <>
        "connect-src 'self' ws:; " <>
        "form-action 'self'"
    )
  end
end
