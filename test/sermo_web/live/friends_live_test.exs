defmodule SermoWeb.FriendsLiveTest do
  use SermoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sermo.Fixtures

  test "renders friends page", %{conn: conn} do
    user = create_user()

    {:ok, _view, html} =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> live(~p"/friends")

    assert html =~ "Friends"
    assert html =~ "Add Friend"
  end

  test "sends friend request", %{conn: conn} do
    user = create_user()
    other = create_user()

    {:ok, view, _html} =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> live(~p"/friends")

    view |> render_hook("search", %{"username" => other.username})
    view |> element("[phx-click=\"send-request\"][phx-value-id=\"#{other.id}\"]") |> render_click()
    assert render(view) =~ "Friend request sent"
  end

  test "shows incoming friend requests", %{conn: conn} do
    user = create_user()
    other = create_user()
    Sermo.Accounts.send_friend_request(other.id, user.id)

    {:ok, view, _html} =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> live(~p"/friends")

    assert view |> render() =~ "Incoming"
    assert view |> render() =~ other.display_name
  end

  test "accepts incoming friend request", %{conn: conn} do
    user = create_user()
    other = create_user()
    {:ok, f} = Sermo.Accounts.send_friend_request(other.id, user.id)

    {:ok, view, _html} =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> live(~p"/friends")

    view |> element("[phx-click=\"accept-request\"][phx-value-id=\"#{f.id}\"]") |> render_click()
    assert view |> render() =~ "Friend request accepted"
  end
end
