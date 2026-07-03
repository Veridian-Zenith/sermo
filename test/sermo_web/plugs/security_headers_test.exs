defmodule SermoWeb.Plugs.SecurityHeadersTest do
  use SermoWeb.ConnCase, async: true

  test "adds security headers to response", %{conn: conn} do
    conn =
      conn
      |> put_resp_content_type("text/html")
      |> SermoWeb.Plugs.SecurityHeaders.call(%{})
      |> send_resp(200, "ok")

    assert get_resp_header(conn, "x-content-type-options") |> hd() == "nosniff"
    assert get_resp_header(conn, "x-frame-options") |> hd() == "DENY"
    assert get_resp_header(conn, "referrer-policy") |> hd() == "strict-origin-when-cross-origin"
    assert get_resp_header(conn, "content-security-policy") |> hd() =~ "default-src 'self'"
  end
end
