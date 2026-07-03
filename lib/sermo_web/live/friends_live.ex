defmodule SermoWeb.FriendsLive do
  use SermoWeb, :live_view

  alias Sermo.Accounts

  def mount(_params, session, socket) do
    current_user = Accounts.get_user(session["user_id"])
    socket = load(socket, current_user)
    {:ok, assign(socket, :search, "")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="h-full overflow-y-auto bg-primary">
        <div class="max-w-lg lg:max-w-2xl mx-auto p-6 space-y-6">
          <div class="flex items-center gap-3 mb-2">
            <.link href="/chat" class="btn btn-ghost rounded-xl px-3 py-1.5 text-xs no-underline">← Back</.link>
            <h1 class="text-2xl font-black text-gradient">Friends</h1>
          </div>

          <div class="p-6 card space-y-4">
            <h2 class="label">Add Friend</h2>
            <form phx-submit="send-request" class="space-y-3">
              <input type="text" name="username" value={@search} placeholder="search by username..."
                class="input-field" phx-input="search" />
              <div :if={@search != ""} class="max-h-40 overflow-y-auto space-y-1">
                <div :for={u <- @search_results} class="flex items-center justify-between px-3 py-2 rounded-xl bg-secondary/50">
                  <span class="text-sm text-white"><%= u.display_name || u.username %></span>
                  <span class="text-xs text-muted">@<%= u.username %></span>
                  <button phx-click="send-request" phx-value-id={u.id}
                    class="btn btn-primary rounded-xl px-3 py-1 text-xs">
                    + Add
                  </button>
                </div>
                <div :if={@search_results == []} class="text-xs text-muted text-center py-2">
                  no users found
                </div>
              </div>
            </form>
          </div>

          <div :if={@incoming != []} class="p-6 card space-y-3">
            <h2 class="label">
              Incoming Requests (<%= length(@incoming) %>)
            </h2>
            <div :for={f <- @incoming} class="flex items-center justify-between px-3 py-2 rounded-xl bg-secondary/50">
              <div class="flex items-center gap-2 min-w-0">
                <.avatar user={f.requester} />
                <div class="min-w-0">
                  <div class="text-sm text-white truncate"><%= f.requester.display_name || f.requester.username %></div>
                  <div class="text-xs text-muted">@<%= f.requester.username %></div>
                </div>
              </div>
              <div class="flex gap-2 shrink-0">
                <button phx-click="accept-request" phx-value-id={f.id}
                  class="btn btn-primary rounded-xl px-3 py-1 text-xs">Accept</button>
                <button phx-click="decline-request" phx-value-id={f.id}
                  class="btn btn-ghost rounded-xl px-3 py-1 text-xs">Decline</button>
              </div>
            </div>
          </div>

          <div :if={@outgoing != []} class="p-6 card space-y-3">
            <h2 class="label">
              Pending Sent (<%= length(@outgoing) %>)
            </h2>
            <div :for={f <- @outgoing} class="flex items-center justify-between px-3 py-2 rounded-xl bg-secondary/50">
              <div class="flex items-center gap-2 min-w-0">
                <.avatar user={f.requested} />
                <div class="min-w-0">
                  <div class="text-sm text-white truncate"><%= f.requested.display_name || f.requested.username %></div>
                  <div class="text-xs text-muted">@<%= f.requested.username %></div>
                </div>
              </div>
              <button phx-click="cancel-request" phx-value-id={f.id}
                class="btn btn-ghost rounded-xl px-3 py-1 text-xs">Cancel</button>
            </div>
          </div>

          <div class="p-6 card space-y-3">
            <h2 class="label">
              Friends (<%= length(@friends) %>)
            </h2>
            <div :if={@friends == []} class="text-xs text-muted text-center py-4">
              no friends yet — search for users above
            </div>
            <div :for={friend <- @friends} class="flex items-center justify-between px-3 py-2 rounded-xl bg-secondary/50">
              <div class="flex items-center gap-2 min-w-0">
                <.avatar user={friend} />
                <div class="min-w-0">
                  <div class="text-sm text-white truncate"><%= friend.display_name || friend.username %></div>
                  <div class="text-xs text-muted">@<%= friend.username %></div>
                </div>
              </div>
              <div class="flex gap-2 shrink-0">
                <button phx-click="message-friend" phx-value-id={friend.id}
                  class="btn btn-ghost rounded-xl px-3 py-1 text-xs">Message</button>
                <button phx-click="remove-friend" phx-value-id={friend.id}
                  class="text-xs text-muted underline">Remove</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def avatar(assigns) do
    ~H"""
    <div class="w-8 h-8 rounded-full bg-secondary border border-[var(--vz-border-color)] overflow-hidden shrink-0 flex items-center justify-center">
      <%= if @user.avatar_path do %>
        <img src={~p"/uploads/avatars/#{@user.avatar_path}"} class="w-full h-full cover" />
      <% else %>
        <span class="text-xs font-bold text-muted"><%= String.first(@user.display_name || @user.username) |> String.upcase() %></span>
      <% end %>
    </div>
    """
  end

  def handle_event("search", %{"username" => query}, socket) do
    query = String.trim(query)

    results =
      if query != "" do
        Accounts.list_other_users(socket.assigns.current_user.id)
        |> Enum.filter(fn u ->
          String.contains?(String.downcase(u.username), String.downcase(query)) or
            (u.display_name &&
               String.contains?(String.downcase(u.display_name), String.downcase(query)))
        end)
      else
        []
      end

    {:noreply, assign(socket, search: query, search_results: results)}
  end

  def handle_event("send-request", %{"id" => id}, socket) do
    case Accounts.send_friend_request(socket.assigns.current_user.id, id) do
      {:ok, _} ->
        {:noreply,
         load(socket, socket.assigns.current_user) |> put_flash(:info, "Friend request sent")}

      {:error, :already_exists} ->
        {:noreply, put_flash(socket, :error, "Request already exists")}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("accept-request", %{"id" => id}, socket) do
    case Accounts.accept_friend_request(id, socket.assigns.current_user.id) do
      {:ok, _} ->
        {:noreply,
         load(socket, socket.assigns.current_user) |> put_flash(:info, "Friend request accepted")}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("decline-request", %{"id" => id}, socket) do
    case Accounts.decline_friend_request(id, socket.assigns.current_user.id) do
      {:ok, _} ->
        {:noreply, load(socket, socket.assigns.current_user)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("cancel-request", %{"id" => id}, socket) do
    case Accounts.cancel_friend_request(id, socket.assigns.current_user.id) do
      {:ok, _} ->
        {:noreply, load(socket, socket.assigns.current_user)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("remove-friend", %{"id" => id}, socket) do
    case Accounts.remove_friend(socket.assigns.current_user.id, id) do
      {:ok, _} ->
        {:noreply,
         load(socket, socket.assigns.current_user) |> put_flash(:info, "Friend removed")}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("message-friend", %{"id" => _id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/chat")}
  end

  defp load(socket, current_user) do
    socket
    |> assign(:current_user, current_user)
    |> assign(:friends, Accounts.list_friends(current_user.id))
    |> assign(:incoming, Accounts.list_incoming_requests(current_user.id))
    |> assign(:outgoing, Accounts.list_outgoing_requests(current_user.id))
    |> assign(:search_results, [])
  end
end
