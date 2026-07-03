defmodule SermoWeb.NewConversationLiveTest do
  use SermoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sermo.Fixtures

  test "renders new conversation page", %{conn: conn} do
    user = create_user()

    {:ok, _view, html} =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> live(~p"/conversations/new")

    assert html =~ "New Conversation"
  end

  test "shows no users message when alone", %{conn: conn} do
    user = create_user()

    {:ok, _view, html} =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> live(~p"/conversations/new")

    assert html =~ "no other users yet"
  end

  test "shows other users when they exist", %{conn: conn} do
    user = create_user()
    _other = create_user()

    {:ok, _view, html} =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> live(~p"/conversations/new")

    refute html =~ "no other users yet"
  end
end
