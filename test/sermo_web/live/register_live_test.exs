defmodule SermoWeb.RegisterLiveTest do
  use SermoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders registration form", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/register")
    assert view |> element("h1") |> render() =~ "Create Account"
    assert view |> element("form") |> render() =~ "Password"
  end
end
