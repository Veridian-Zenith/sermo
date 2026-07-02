defmodule SermoWeb.ProfileLive do
  use SermoWeb, :live_view

  alias Sermo.Accounts

  def mount(_params, session, socket) do
    current_user = Accounts.get_user(session["user_id"])

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:display_name, current_user.display_name || "")
      |> assign_password_form()

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="h-full flex items-center justify-center bg-primary">
        <div class="w-full max-w-sm mx-4">
          <div class="flex items-center gap-3 mb-6">
            <.link href="/chat" class="btn btn-ghost rounded-xl px-3 py-1.5 text-xs">← Back</.link>
            <h1 class="text-2xl font-black text-gradient">Profile</h1>
          </div>
          <div class="space-y-6">
            <div class="p-8 card space-y-4">
              <h2 class="text-sm font-semibold text-secondary uppercase tracking-wide">Display Name</h2>
              <form phx-submit="update-profile" class="space-y-3">
                <input type="text" name="display_name" value={@display_name} placeholder="set a display name"
                  class="input-field" />
                <button type="submit" class="btn btn-primary w-full py-3 rounded-xl text-sm">
                  Save
                </button>
              </form>
            </div>
            <div class="p-8 card space-y-4">
              <h2 class="text-sm font-semibold text-secondary uppercase tracking-wide">Change Password</h2>
              <form phx-submit="change-password" class="space-y-3">
                <input type="password" name="password" placeholder="new password (min 6 chars)"
                  class="input-field" />
                <button type="submit" class="btn btn-primary w-full py-3 rounded-xl text-sm">
                  Update Password
                </button>
              </form>
            </div>
            <div class="text-xs text-muted text-center">
              logged in as <span class="text-white font-semibold"><%= @current_user.username %></span>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("update-profile", %{"display_name" => display_name}, socket) do
    display_name = if display_name == "", do: nil, else: display_name

    case Accounts.update_user(socket.assigns.current_user, %{display_name: display_name}) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> assign(:display_name, user.display_name || "")
         |> put_flash(:info, "Display name updated")}

      {:error, changeset} ->
        error = extract_error(changeset)
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  def handle_event("change-password", %{"password" => password}, socket) do
    if password == "" do
      {:noreply, put_flash(socket, :error, "Password cannot be empty")}
    else
      case Accounts.change_password(socket.assigns.current_user, %{password: password}) do
        {:ok, _user} ->
          {:noreply, socket |> assign_password_form() |> put_flash(:info, "Password changed")}

        {:error, changeset} ->
          error = extract_error(changeset)
          {:noreply, put_flash(socket, :error, error)}
      end
    end
  end

  defp assign_password_form(socket) do
    assign(socket, password: "")
  end

  defp extract_error(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end)
    |> Enum.map_join(", ", fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
  end
end
