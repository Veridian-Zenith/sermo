defmodule SermoWeb.NewConversationLive do
  use SermoWeb, :live_view

  alias Sermo.Conversations
  alias Sermo.Accounts

  def mount(_params, session, socket) do
    current_user = Accounts.get_user(session["user_id"])
    users = list_users(current_user.id)
    form = to_form(%{"type" => "direct", "name" => "", "other_user_id" => ""}, as: :conv)

    {:ok,
     assign(socket,
       current_user: current_user,
       users: users,
       filtered_users: users,
       form: form,
       search: ""
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="h-full flex items-center justify-center bg-primary">
        <div class="w-full max-w-md mx-4">
          <div class="flex items-center gap-3 mb-6">
            <.link href="/chat" class="btn btn-ghost rounded-xl px-3 py-1.5 text-xs">← Back</.link>
            <h1 class="text-2xl font-black text-gradient">New Conversation</h1>
          </div>
          <.form for={@form} id="conv-form" phx-submit="create" class="space-y-4 p-8 card">
            <div>
              <label class="label">Type</label>
              <select name="conv[type]" class="select-field mt-1">
                <option value="direct">Direct Message</option>
                <option value="group">Group</option>
              </select>
            </div>
            <div>
              <label for="name" class="label">Group Name</label>
              <input type="text" name="conv[name]" id="name" placeholder="only for groups"
                class="input-field mt-1" />
            </div>
            <div>
              <label for="search" class="label">Search Users</label>
              <input type="text" name="search" id="search" value={@search}
                phx-input="search-users" placeholder="start typing to filter..."
                class="input-field mt-1" />
            </div>
            <div>
              <label for="other_user_id" class="label">Select User</label>
              <select name="conv[other_user_id]" id="other_user_id" size={min(5, length(@filtered_users))}
                class="select-field mt-1">
                <option value="">select a user...</option>
                <option :for={u <- @filtered_users} value={u.id}><%= u.display_name || u.username %></option>
              </select>
            </div>
            <button type="submit" class="btn btn-primary w-full py-3 rounded-xl text-sm">
              Create
            </button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("search-users", %{"search" => search}, socket) do
    search = String.downcase(search)

    filtered =
      Enum.filter(socket.assigns.users, fn u ->
        String.contains?(String.downcase(u.username), search) or
          (u.display_name && String.contains?(String.downcase(u.display_name), search))
      end)

    {:noreply, assign(socket, filtered_users: filtered, search: search)}
  end

  def handle_event("create", %{"conv" => params}, socket) do
    case params["type"] do
      "direct" ->
        other_id = params["other_user_id"]

        if other_id == "" do
          {:noreply, put_flash(socket, :error, "Select a user")}
        else
          case Conversations.create_direct_conversation(socket.assigns.current_user.id, other_id) do
            {:ok, conv} ->
              notify_participants(conv)
              {:noreply, redirect(socket, to: ~p"/chat")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Could not create conversation")}
          end
        end

      "group" ->
        name = params["name"]

        if name == "" do
          {:noreply, put_flash(socket, :error, "Group needs a name")}
        else
          other_id = params["other_user_id"]
          member_ids = if other_id == "", do: [], else: [other_id]

          case Conversations.create_group_conversation(
                 socket.assigns.current_user.id,
                 name,
                 member_ids
               ) do
            {:ok, conv} ->
              notify_participants(conv)
              {:noreply, redirect(socket, to: ~p"/chat")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Could not create conversation")}
          end
        end
    end
  end

  defp list_users(current_user_id) do
    import Ecto.Query

    Sermo.Repo.all(
      from u in Sermo.Accounts.User,
        where: u.id != ^current_user_id,
        order_by: u.username
    )
  end

  defp notify_participants(conv) do
    conv = Sermo.Repo.preload(conv, :members)

    for member <- conv.members do
      Phoenix.PubSub.broadcast(
        Sermo.PubSub,
        "user:#{member.user_id}",
        {:conversation_updated, conv.id}
      )
    end
  end
end
