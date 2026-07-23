defmodule SermoWeb.NewConversationLive do
  use SermoWeb, :live_view

  alias Sermo.Conversations
  alias Sermo.Accounts

  def mount(_params, session, socket) do
    current_user = Accounts.get_user(session["user_id"])
    users = Accounts.list_other_users(current_user.id)
    form = to_form(%{"type" => "direct", "name" => "", "member_ids" => []}, as: :conv)

    {:ok,
     assign(socket,
       current_user: current_user,
       users: users,
       filtered_users: users,
       form: form,
       search: "",
       selected_ids: MapSet.new()
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="h-full overflow-y-auto bg-primary">
        <div class="w-full max-w-md lg:max-w-xl mx-auto p-6">
          <div class="flex items-center gap-3 mb-6">
            <.link href="/chat" class="btn btn-ghost rounded-xl px-3 py-1.5 text-xs no-underline">← Back</.link>
            <h1 class="text-2xl font-black text-gradient">New Conversation</h1>
          </div>

          <div :if={@users == []} class="p-6 card text-center space-y-3">
            <div class="text-lg">👋</div>
            <p class="text-sm text-secondary leading-relaxed">
              no other users yet<br />
              share this app with friends to get started
            </p>
            <p class="text-xs text-muted mt-2">
              give them the URL of this server to sign up
            </p>
          </div>

          <div :if={@users != []} class="space-y-4">
            <.form for={@form} id="conv-form" phx-submit="create" class="space-y-4 p-6 card">
              <div>
                <label class="label">Type</label>
                <select name="conv[type]" id="conv_type" class="select-field mt-1" phx-change="change-type">
                  <option value="direct" selected={@form[:type].value == "direct"}>Direct Message</option>
                  <option value="group" selected={@form[:type].value == "group"}>Group</option>
                </select>
              </div>
              <div :if={@form[:type].value == "group"}>
                <label for="name" class="label">Group Name</label>
                <input type="text" name="conv[name]" id="name" placeholder="name this group"
                  class="input-field mt-1" />
              </div>
              <div>
                <label for="search" class="label">Search Users</label>
                <input type="text" name="search" id="search" value={@search}
                  phx-input="search-users" placeholder="start typing to filter..."
                  class="input-field mt-1" />
              </div>
              <div>
                <label class="label"><%= if @form[:type].value == "group", do: "Select Members", else: "Select User" %></label>
                <div class="mt-1 max-h-48 overflow-y-auto space-y-1 border border-[var(--vz-border-color)] rounded-2xl p-2">
                  <div :for={u <- @filtered_users} class="flex items-center gap-2 px-3 py-2 rounded-xl hover:bg-accent-subtle transition-fast cursor-pointer"
                    phx-click="toggle-user" phx-value-id={u.id}>
                    <input type={if @form[:type].value == "direct", do: "radio", else: "checkbox"}
                      name={if @form[:type].value == "direct", do: "conv[member_ids]", else: "conv[member_ids][]"}
                      value={u.id}
                      checked={u.id in @selected_ids}
                      class="accent-[var(--vz-accent-vibrant)] cursor-pointer" />
                    <span class="text-sm text-white"><%= u.display_name || u.username %></span>
                    <span :if={u.display_name} class="text-xs text-muted ml-auto">@<%= u.username %></span>
                  </div>
                  <div :if={@filtered_users == []} class="text-xs text-muted text-center py-2">
                    no users match that filter
                  </div>
                </div>
              </div>
              <div :if={@form[:type].value == "group" && MapSet.size(@selected_ids) > 0} class="text-xs text-muted">
                <%= MapSet.size(@selected_ids) %> user(s) selected
              </div>
              <button type="submit" class="btn btn-primary w-full py-3 rounded-xl text-sm">
                Create
              </button>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("change-type", %{"conv" => %{"type" => type}}, socket) do
    form =
      to_form(
        %{"type" => type, "name" => socket.assigns.form[:name].value || "", "member_ids" => []},
        as: :conv
      )

    {:noreply, assign(socket, form: form, selected_ids: MapSet.new())}
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

  def handle_event("toggle-user", %{"id" => id}, socket) do
    selected = socket.assigns.selected_ids
    type = socket.assigns.form[:type].value

    selected =
      if type == "direct" do
        MapSet.new([id])
      else
        if MapSet.member?(selected, id),
          do: MapSet.delete(selected, id),
          else: MapSet.put(selected, id)
      end

    {:noreply, assign(socket, selected_ids: selected)}
  end

  def handle_event("create", %{"conv" => params}, socket) do
    case params["type"] do
      "direct" -> create_direct(socket)
      "group" -> create_group(params, socket)
    end
  end

  defp create_direct(socket) do
    member_ids = socket.assigns.selected_ids |> MapSet.to_list()

    if member_ids == [] do
      {:noreply, put_flash(socket, :error, "Select a user")}
    else
      other_id = hd(member_ids)

      case Conversations.create_direct_conversation(socket.assigns.current_user.id, other_id) do
        {:ok, conv} ->
          Conversations.broadcast_conversation_update(conv)
          {:noreply, push_navigate(socket, to: ~p"/chat")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not create conversation")}
      end
    end
  end

  defp create_group(params, socket) do
    name = params["name"]
    member_ids = socket.assigns.selected_ids |> MapSet.to_list()

    cond do
      name == "" ->
        {:noreply, put_flash(socket, :error, "Group needs a name")}

      member_ids == [] ->
        {:noreply, put_flash(socket, :error, "Select at least one member")}

      true ->
        case Conversations.create_group_conversation(
               socket.assigns.current_user.id,
               name,
               member_ids
             ) do
          {:ok, conv} ->
            Conversations.broadcast_conversation_update(conv)
            {:noreply, push_navigate(socket, to: ~p"/chat")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not create conversation")}
        end
    end
  end
end
