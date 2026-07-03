defmodule SermoWeb.ProfileLiveTest do
  use SermoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sermo.Fixtures

  test "renders profile page", %{conn: conn} do
    user = create_user()

    {:ok, _view, html} =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> live(~p"/profile")

    assert html =~ "Profile"
    assert html =~ user.display_name
  end

  test "updates display name", %{conn: conn} do
    user = create_user()

    {:ok, view, _html} =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> live(~p"/profile")

    view
    |> form("[phx-submit=\"save-display-name\"]", %{display_name: "NewName"})
    |> render_submit()

    assert render(view) =~ "Display name updated"
  end

  test "updates bio", %{conn: conn} do
    user = create_user()

    {:ok, view, _html} =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> live(~p"/profile")

    view
    |> form("[phx-submit=\"save-bio\"]", %{bio: "Hello, I am a test user!"})
    |> render_submit()

    assert render(view) =~ "Bio updated"
  end

  test "changes password", %{conn: conn} do
    user = create_user()

    {:ok, view, _html} =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> live(~p"/profile")

    view
    |> form("[phx-submit=\"change-password\"]", %{password: "newpass123"})
    |> render_submit()

    assert render(view) =~ "Password changed"
  end
end
