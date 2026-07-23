defmodule SermoWeb.ChatLive do
  use SermoWeb, :live_view

  alias Sermo.Conversations
  alias Sermo.Accounts

  @typing_timeout 3_000

  def mount(_params, session, socket) do
    current_user = Accounts.get_user(session["user_id"])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Sermo.PubSub, "user:#{current_user.id}")

      uid = "#{current_user.id}"
      SermoWeb.Presence.track(self(), "presence", uid, %{user_id: uid})
    end

    online = if connected?(socket), do: fetch_online_users(), else: %{}

    conversations = Conversations.list_conversations(current_user.id)
    enriched = Conversations.enrich_conversations(conversations, current_user.id)
    last_msgs = load_last_messages(enriched)
    friends = Accounts.list_friends(current_user.id)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(
        conversations: enriched,
        current_conversation_id: nil,
        new_message: "",
        editing_message_id: nil,
        editing_body: "",
        last_messages: last_msgs,
        typing_users: %{},
        online_users: online,
        friends: friends,
        friend_statuses: %{},
        friend_requests: Accounts.list_incoming_requests(current_user.id)
      )
      |> stream(:messages, [])

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    conv_id = params["conversation_id"]

    if conv_id && Conversations.member?(socket.assigns.current_user.id, conv_id) do
      messages = Conversations.list_messages(conv_id)

      {:noreply,
       socket
       |> assign(current_conversation_id: conv_id, editing_message_id: nil, editing_body: "")
       |> stream(:messages, messages, reset: true)}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex h-full bg-primary">
        <aside class="w-72 lg:w-80 border-r flex flex-col bg-secondary backdrop-blur-sm overflow-x-hidden select-none shrink-0">
          <div class="p-4 sidebar-header flex justify-between items-center">
            <h2 class="text-lg font-black text-gradient">Sermo</h2>
            <.link href="/conversations/new" class="btn btn-ghost rounded-xl px-3 py-1.5 text-xs no-underline">
              + New
            </.link>
          </div>
          <div class="flex-1 overflow-y-auto overflow-x-hidden">
            <div :if={@conversations == []} class="p-6 text-muted text-center text-sm space-y-3">
              <div class="text-lg">☕</div>
              <div>no conversations yet</div>
              <.link href="/conversations/new" class="btn btn-ghost rounded-xl px-4 py-2 text-xs mt-2 inline-block">
                start one
              </.link>
            </div>
            <div :for={conv <- @conversations}
              phx-click="select-conversation" phx-value-id={conv.id}
              class={"sidebar-item " <> (if @current_conversation_id == conv.id, do: "active", else: "")}>
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-2 min-w-0">
                  <div class="font-semibold text-sm text-white truncate"><%= conv.display_name %></div>
                  <div :if={conv.type == "group"} class="text-xs text-muted shrink-0 tracking-wider uppercase">group</div>
                </div>
                <.dot on={Map.has_key?(@online_users, other_id(conv, @current_user.id))} />
              </div>
              <div :if={preview = Map.get(@last_messages, conv.id)} class="text-xs text-muted mt-1 truncate">
                <%= preview.sender.username %>: <%= preview.body %>
              </div>
            </div>
          </div>
          <div class="px-4 py-3 border-t">
            <div class="flex items-center justify-between mb-2">
              <span class="label">Friends</span>
              <.link href="/friends" class="text-xs text-accent font-semibold hover-bright transition">manage</.link>
            </div>
            <div :if={length(@friend_requests) > 0} class="mb-2 px-3 py-1.5 rounded-xl bg-accent/10 border border-accent/30 text-xs text-accent">
              <%= length(@friend_requests) %> pending request<%= if length(@friend_requests) != 1, do: "s" %>
            </div>
            <div :if={@friends == []} class="text-xs text-muted pl-1">no friends yet</div>
            <div :for={friend <- @friends} class="flex items-center gap-2 px-2 py-1.5 rounded-xl hover:bg-accent-subtle transition cursor-default group">
              <.dot on={Map.has_key?(@online_users, friend.id)} />
              <span class="text-xs truncate text-muted group-hover:text-white transition"><%= friend.display_name || friend.username %></span>
            </div>
          </div>
          <div class="p-3 sidebar-footer text-sm text-secondary flex justify-between items-center">
            <div class="flex items-center gap-2 min-w-0">
              <.dot on={Map.has_key?(@online_users, @current_user.id)} />
              <span class="font-medium truncate"><%= @current_user.display_name || @current_user.username %></span>
            </div>
            <div class="flex gap-2 shrink-0">
              <.link href="/profile" class="text-xs text-accent font-semibold hover-bright transition">profile</.link>
              <.link href="/logout" class="text-xs text-accent font-semibold hover-bright transition">exit</.link>
            </div>
          </div>
        </aside>
        <main class="flex-1 flex flex-col bg-primary min-w-0">
          <div :if={@current_conversation_id == nil} class="flex-1 flex items-center justify-center p-4">
            <div class="text-center">
              <div class="text-4xl font-black text-gradient select-none">Sermo</div>
              <p class="text-sm text-muted mt-2">select a conversation to begin</p>
            </div>
          </div>
          <div :if={@current_conversation_id != nil} class="flex-1 flex flex-col min-h-0">
            <div class="flex items-center justify-between px-4 py-3 border-b chat-header bg-secondary/30 shrink-0">
              <div class="flex items-center gap-2 min-w-0">
                <.dot on={Map.has_key?(@online_users, conv_other_id(@current_conversation_id, @conversations, @current_user.id))} />
                <div class="text-sm font-semibold text-white truncate">
                  <%= conv_name(@current_conversation_id, @conversations) %>
                </div>
              </div>
              <button phx-click="leave-conversation" class="text-xs text-muted hover-bright transition">leave</button>
            </div>
            <div id="messages" phx-update="stream" class="flex-1 overflow-y-auto p-4 space-y-3">
              <div :for={{id, msg} <- @streams.messages} id={id} class={"flex " <> (if msg.sender_id == @current_user.id, do: "justify-end", else: "justify-start")}>
                <div class={"max-w-md lg:msg-max px-4 py-3 relative group shadow-card " <> (if msg.sender_id == @current_user.id, do: "msg-own", else: "msg-other")}>
                  <div :if={msg.sender_id != @current_user.id} class="text-xs font-semibold text-accent-dim mb-0.5 tracking-wider uppercase">
                    <%= msg.sender.display_name || msg.sender.username %>
                  </div>
                  <div :if={@editing_message_id != msg.id} class="text-sm whitespace-pre-wrap leading-relaxed"><%= msg.body %></div>
                  <form :if={@editing_message_id == msg.id} phx-submit="update-message" class="flex gap-2">
                    <input type="hidden" name="message_id" value={msg.id} />
                    <input type="text" name="body" value={@editing_body}
                      class="input-field flex-1 text-sm" phx-keydown="cancel-edit" phx-key="Escape" />
                  </form>
                  <div class={"text-xs mt-1 flex items-center gap-2 " <> (if msg.sender_id == @current_user.id, do: "text-black/60", else: "text-muted")}>
                    <span><%= format_time(msg.inserted_at) %></span>
                    <span :if={msg.updated_at != msg.inserted_at} class="italic">(edited)</span>
                  </div>
                  <div :if={msg.sender_id == @current_user.id && @editing_message_id != msg.id}
                    class="absolute top-1 right-1 flex gap-1 opacity-0 group-hover:opacity-100 transition-fast">
                    <button phx-click="edit-message" phx-value-id={msg.id} phx-value-body={msg.body}
                      class="text-xs bg-black/30 px-1.5 py-0.5 rounded">edit</button>
                    <button phx-click="delete-message" phx-value-id={msg.id}
                      class="text-xs bg-black/30 px-1.5 py-0.5 rounded">del</button>
                  </div>
                </div>
              </div>
            </div>
            <div :if={typing = typing_text(@typing_users, @current_conversation_id, @current_user.id)} class="px-4 py-1.5 text-xs text-muted italic">
              <%= typing %>
            </div>
            <form phx-submit="send-message" class="chat-input p-4 flex gap-3 bg-secondary/50">
              <input type="text" name="body" value={@new_message} placeholder="type a message..."
                class="input-field flex-1" phx-change="typing" />
              <button type="submit" class="btn btn-primary rounded-xl px-6 py-3 text-sm">
                Send
              </button>
            </form>
          </div>
        </main>
      </div>
    </Layouts.app>
    """
  end

  def dot(assigns) do
    ~H"""
    <span :if={@on}
      class="w-2 h-2 rounded-full bg-green-500 shrink-0" title="online">
    </span>
    <span :if={!@on && @on != nil}
      class="w-2 h-2 rounded-full bg-gray-600 shrink-0" title="offline">
    </span>
    """
  end

  def handle_event("select-conversation", %{"id" => id}, socket) do
    messages = Conversations.list_messages(id)
    socket = update_last_messages(socket, [id])

    {:noreply,
     socket
     |> assign(current_conversation_id: id, editing_message_id: nil, editing_body: "")
     |> stream(:messages, messages, reset: true)}
  end

  def handle_event("send-message", %{"body" => body}, socket) do
    body = String.trim(body)

    if body != "" and socket.assigns.current_conversation_id do
      conv_id = socket.assigns.current_conversation_id

      case Conversations.send_message(conv_id, socket.assigns.current_user.id, body) do
        {:ok, _msg} ->
          messages = Conversations.list_messages(conv_id)
          socket = update_last_messages(socket, [conv_id])

          {:noreply,
           socket
           |> assign(new_message: "")
           |> stream(:messages, messages, reset: true)}

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, assign(socket, new_message: "")}
    end
  end

  def handle_event("typing", %{"_target" => ["body"], "body" => body}, socket) do
    conv_id = socket.assigns.current_conversation_id

    if conv_id && body != "" do
      members = get_conversation_members(socket.assigns.conversations, conv_id)

      Conversations.broadcast_typing(
        conv_id,
        socket.assigns.current_user,
        Enum.map(members, & &1.user_id)
      )
    end

    {:noreply, assign(socket, new_message: body)}
  end

  def handle_event("edit-message", %{"id" => id, "body" => body}, socket) do
    {:noreply, assign(socket, editing_message_id: id, editing_body: body)}
  end

  def handle_event("update-message", %{"message_id" => id, "body" => body}, socket) do
    body = String.trim(body)

    if body != "" do
      case Conversations.update_message(id, socket.assigns.current_user.id, %{body: body}) do
        {:ok, _msg} ->
          messages = Conversations.list_messages(socket.assigns.current_conversation_id)

          {:noreply,
           socket
           |> assign(editing_message_id: nil, editing_body: "")
           |> stream(:messages, messages, reset: true)}

        _ ->
          {:noreply, assign(socket, editing_message_id: nil, editing_body: "")}
      end
    else
      {:noreply, assign(socket, editing_message_id: nil, editing_body: "")}
    end
  end

  def handle_event("cancel-edit", _, socket) do
    {:noreply, assign(socket, editing_message_id: nil, editing_body: "")}
  end

  def handle_event("delete-message", %{"id" => id}, socket) do
    case Conversations.delete_message(id, socket.assigns.current_user.id) do
      {:ok, _msg} ->
        messages = Conversations.list_messages(socket.assigns.current_conversation_id)
        {:noreply, stream(socket, :messages, messages, reset: true)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("leave-conversation", _, socket) do
    conv_id = socket.assigns.current_conversation_id

    if conv_id do
      Conversations.remove_member(conv_id, socket.assigns.current_user.id)
      Conversations.broadcast_member_removed(conv_id, socket.assigns.current_user.id)

      conversations = Conversations.list_conversations(socket.assigns.current_user.id)
      enriched = Conversations.enrich_conversations(conversations, socket.assigns.current_user.id)

      {:noreply,
       socket
       |> assign(
         conversations: enriched,
         current_conversation_id: nil,
         last_messages: load_last_messages(enriched)
       )
       |> stream(:messages, [], reset: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:new_message, msg}, socket) do
    socket =
      if socket.assigns.current_conversation_id == msg.conversation_id do
        messages = Conversations.list_messages(msg.conversation_id)
        socket |> stream(:messages, messages, reset: true)
      else
        socket
      end

    socket = update_last_messages(socket, [msg.conversation_id])
    {:noreply, socket}
  end

  def handle_info({:message_updated, msg}, socket) do
    if socket.assigns.current_conversation_id == msg.conversation_id do
      messages = Conversations.list_messages(msg.conversation_id)
      {:noreply, stream(socket, :messages, messages, reset: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:message_deleted, _msg_id, conv_id}, socket) do
    if socket.assigns.current_conversation_id == conv_id do
      messages = Conversations.list_messages(conv_id)
      {:noreply, stream(socket, :messages, messages, reset: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:you_were_removed, _conv_id}, socket) do
    refresh_all(socket)
  end

  def handle_info({:conversation_updated, _conv_id}, socket) do
    refresh_all(socket)
  end

  def handle_info({:typing, conv_id, user}, socket) do
    if conv_id == socket.assigns.current_conversation_id do
      typing = socket.assigns.typing_users
      conv_typing = Map.get(typing, conv_id, %{})
      conv_typing = Map.put(conv_typing, user.id, {user, System.monotonic_time()})
      typing = Map.put(typing, conv_id, conv_typing)

      Process.send_after(self(), {:clear_typing, conv_id, user.id}, @typing_timeout)

      {:noreply, assign(socket, typing_users: typing)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:clear_typing, conv_id, user_id}, socket) do
    case socket.assigns.typing_users do
      %{^conv_id => users} ->
        updated = Map.delete(users, user_id)

        typing =
          if updated == %{},
            do: Map.delete(socket.assigns.typing_users, conv_id),
            else: Map.put(socket.assigns.typing_users, conv_id, updated)

        {:noreply, assign(socket, typing_users: typing)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    online = socket.assigns.online_users

    online =
      Enum.reduce(diff.joins, online, fn {_ref, %{metas: metas}}, acc ->
        Enum.reduce(metas, acc, &add_online_user/2)
      end)

    online =
      Enum.reduce(diff.leaves, online, fn {_ref, %{metas: metas}}, acc ->
        Enum.reduce(metas, acc, &remove_online_user/2)
      end)

    {:noreply, assign(socket, online_users: online)}
  end

  defp fetch_online_users do
    SermoWeb.Presence.list("presence")
    |> Enum.reduce(%{}, fn {_ref, %{metas: metas}}, acc ->
      Enum.reduce(metas, acc, &add_online_user/2)
    end)
  end

  defp add_online_user(%{user_id: id}, acc) when is_binary(id), do: Map.put(acc, id, true)
  defp add_online_user(_meta, acc), do: acc

  defp remove_online_user(%{user_id: id}, acc) when is_binary(id), do: Map.delete(acc, id)
  defp remove_online_user(_meta, acc), do: acc

  defp refresh_all(socket) do
    conversations = Conversations.list_conversations(socket.assigns.current_user.id)
    enriched = Conversations.enrich_conversations(conversations, socket.assigns.current_user.id)

    {:noreply,
     assign(socket, conversations: enriched, last_messages: load_last_messages(enriched))}
  end

  defp update_last_messages(socket, conv_ids) do
    last_msgs = socket.assigns.last_messages

    assign(
      socket,
      last_messages:
        Enum.reduce(conv_ids, last_msgs, fn id, acc ->
          case Conversations.last_message(id) do
            nil -> acc
            msg -> Map.put(acc, id, msg)
          end
        end)
    )
  end

  defp load_last_messages(conversations) do
    Enum.reduce(conversations, %{}, fn conv, acc ->
      case Conversations.last_message(conv.id) do
        nil -> acc
        msg -> Map.put(acc, conv.id, msg)
      end
    end)
  end

  defp get_conversation_members(conversations, conv_id) do
    case Enum.find(conversations, fn c -> c.id == conv_id end) do
      nil -> []
      conv -> conv.members
    end
  end

  defp conv_name(conv_id, conversations) do
    case Enum.find(conversations, fn c -> c.id == conv_id end) do
      nil -> ""
      conv -> conv.display_name
    end
  end

  defp other_id(conv, current_user_id) do
    if conv.type == "direct" do
      other = Enum.find(conv.members, fn m -> m.user_id != current_user_id end)
      other && other.user_id
    end
  end

  defp conv_other_id(conv_id, conversations, current_user_id) do
    case Enum.find(conversations, fn c -> c.id == conv_id end) do
      nil -> nil
      conv -> other_id(conv, current_user_id)
    end
  end

  defp typing_text(typing_users, conv_id, current_user_id) do
    users = Map.get(typing_users, conv_id, %{})

    names =
      for {user, _time} <- Map.values(users),
          user.id != current_user_id,
          do: user.display_name || user.username

    case names do
      [] -> nil
      [name] -> "#{name} is typing..."
      [name1, name2] -> "#{name1} and #{name2} are typing..."
      [name1, name2 | _] -> "#{name1}, #{name2} and others are typing..."
    end
  end

  defp format_time(nil), do: ""

  defp format_time(dt) do
    Calendar.strftime(dt, "%b %d %H:%M")
  end
end
