defmodule SermoWeb.RecoveryDownloadControllerTest do
  use SermoWeb.ConnCase, async: false

  import Sermo.Fixtures

  defp register_and_extract_token(conn) do
    username = unique_username()

    conn =
      post(conn, ~p"/register", %{
        username: username,
        password: "password123",
        display_name: "Recovery User"
      })

    location = redirected_to(conn)
    %{"token" => token} = URI.decode_query(URI.parse(location).query)
    {conn, token}
  end

  test "GET /recovery-keys/download returns the keys as an attachment", %{conn: conn} do
    {conn, token} = register_and_extract_token(conn)

    conn = get(conn, ~p"/recovery-keys/download?token=#{token}")

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") |> List.first() =~ "text/plain"
    assert get_resp_header(conn, "content-disposition") |> List.first() =~ "attachment"
    assert conn.resp_body =~ "Recovery Keys"
  end

  test "rejects a missing token with 404", %{conn: conn} do
    user = create_user()
    conn = post(conn, ~p"/session", %{username: user.username, password: "password123"})

    conn = get(conn, ~p"/recovery-keys/download")
    assert conn.status == 404
  end

  test "rejects an invalid token with 404", %{conn: conn} do
    user = create_user()
    conn = post(conn, ~p"/session", %{username: user.username, password: "password123"})

    conn = get(conn, ~p"/recovery-keys/download?token=not-a-real-token")
    assert conn.status == 404
  end
end
