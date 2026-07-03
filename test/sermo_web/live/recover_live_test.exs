defmodule SermoWeb.RecoverLiveTest do
  use SermoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sermo.Fixtures

  test "renders recovery form", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/recover")
    assert view |> element("h1") |> render() =~ "Recover Account"
  end

  test "shows error for empty username", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/recover")
    view |> element("#username") |> render_change(%{username: ""})
    view |> element("button") |> render_click()
    assert render(view) =~ "enter your username"
  end

  test "shows error for unknown username", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/recover")
    view |> element("#username") |> render_change(%{username: "nobody"})
    view |> element("button") |> render_click()
    assert render(view) =~ "no account found"
  end

  test "proceeds to key step for user with recovery keys", %{conn: conn} do
    user = create_user()
    Sermo.Accounts.generate_recovery_keys(user, 1)

    {:ok, view, _html} = live(conn, ~p"/recover")
    view |> element("#username") |> render_change(%{username: user.username})
    view |> element("button") |> render_click()
    assert render(view) =~ "Step 2"
  end
end
