defmodule SermoWeb.RecoveryKeysLiveTest do
  use SermoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sermo.Fixtures

  test "redirects to chat without token", %{conn: conn} do
    user = create_user()

    assert {:error, {:live_redirect, %{to: "/chat"}}} =
             conn
             |> Plug.Test.init_test_session(%{user_id: user.id})
             |> live(~p"/recovery-keys")
  end

  test "renders keys with valid token", %{conn: conn} do
    user = create_user()
    {:ok, keys} = Sermo.Accounts.generate_recovery_keys(user, 1)

    token =
      Phoenix.Token.sign(SermoWeb.Endpoint, "recovery-download",
        Enum.map_join(keys, "|", fn k -> "#{k.id}:#{k.key}" end)
      )

    {:ok, view, _html} =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> live(~p"/recovery-keys?token=#{token}")

    assert view |> element("h1") |> render() =~ "Recovery Keys"
    assert view |> render() =~ hd(keys).key
  end
end
