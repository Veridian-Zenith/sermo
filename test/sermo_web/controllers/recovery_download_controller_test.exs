defmodule SermoWeb.RecoveryDownloadControllerTest do
  use SermoWeb.ConnCase, async: true

  import Sermo.Fixtures

  describe "GET /recovery-keys/download" do
    test "returns 404 without token", %{conn: conn} do
      user = create_user()

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user.id})
        |> get(~p"/recovery-keys/download")

      assert html_response(conn, 404)
    end

    test "returns 404 for invalid token", %{conn: conn} do
      user = create_user()

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user.id})
        |> get(~p"/recovery-keys/download?token=bogus")

      assert html_response(conn, 404)
    end

    test "downloads recovery keys text file with valid token", %{conn: conn} do
      user = create_user()
      {:ok, keys} = Sermo.Accounts.generate_recovery_keys(user, 1)

      token =
        Phoenix.Token.sign(SermoWeb.Endpoint, "recovery-download",
          Enum.map_join(keys, "|", fn k -> "#{k.id}:#{k.key}" end)
        )

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user.id})
        |> get(~p"/recovery-keys/download?token=#{token}")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> hd() =~ "text/plain"
      assert conn.resp_body =~ user.username
    end
  end
end
