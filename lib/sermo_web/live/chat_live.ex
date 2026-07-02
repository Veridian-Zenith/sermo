defmodule SermoWeb.ChatLive do
  use SermoWeb, :live_view

  alias Sermo.Conversations
  alias Sermo.Accounts

  def mount(_params, session, socket) do
    current_user = Accounts.get_user(session["user_id"])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Sermo.PubSub, "user:#{current_user.id}")
    end

    conversations = Conversations.list_conversations(current_user.id)
    enriched = Conversations.enrich_conversations(conversations, current_user.id)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(conversations: enriched, current_conversation_id: nil, new_message: "")
      |> assign(editing_message_id: nil, editing_body: "")
      |> stream(:messages, [])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex h-full bg-primary">
        <aside class="w-72 border-r flex flex-col bg-secondary overflow-x-hidden select-none">
          <div class="p-4 sidebar-header flex justify-between items-center">
            <h2 class="text-lg font-black text-gradient">Sermo</h2>
            <button phx-click="new-conversation" class="btn btn-ghost rounded-xl px-3 py-1.5 text-xs">
              + New
            </button>
          </div>
          <div class="flex-1 overflow-y-auto overflow-x-hidden">
            <div :for={conv <- @conversations}
              phx-click="select-conversation" phx-value-id={conv.id}
              class={"sidebar-item " <> (if @current_conversation_id == conv.id, do: "active", else: "")}>
              <div class="flex items-center justify-between">
                <div class="font-semibold text-sm text-white truncate"><%= conv.display_name %></div>
                <div :if={conv.type == "group"} class="text-xs text-muted ml-2 shrink-0">group</div>
              </div>
              <div :if={conv.type == "group" && conv.name} class="text-xs text-muted mt-0.5"><%= conv.name %></div>
            </div>
            <div :if={@conversations == []} class="p-6 text-muted text-center text-sm">
              silence...
            </div>
          </div>
          <div class="p-3 sidebar-footer text-sm text-secondary flex justify-between items-center">
            <span class="font-medium truncate"><%= @current_user.display_name || @current_user.username %></span>
            <div class="flex gap-2 shrink-0">
              <.link href="/profile" class="text-xs text-accent font-semibold hover-bright transition">profile</.link>
              <.link href="/logout" class="text-xs text-accent font-semibold hover-bright transition">exit</.link>
            </div>
          </div>
        </aside>
        <main class="flex-1 flex flex-col bg-primary">
          <div :if={@current_conversation_id == nil} class="flex-1 flex items-center justify-center">
            <div class="text-center">
              <div class="text-4xl font-black text-gradient select-none">Sermo</div>
              <p class="text-sm text-muted mt-2">select a conversation to begin</p>
            </div>
          </div>
          <div :if={@current_conversation_id != nil} class="flex-1 flex flex-col">
            <div class="flex items-center justify-between px-4 py-2 border-b bg-secondary/30">
              <div class="text-sm font-semibold text-white truncate">
                <%= conversation_display_name(@current_conversation_id, @conversations) %>
              </div>
              <button phx-click="leave-conversation" class="text-xs text-muted hover-bright transition">leave</button>
            </div>
            <div id="messages" phx-update="stream" class="flex-1 overflow-y-auto p-4 space-y-3">
              <div :for={{id, msg} <- @streams.messages} id={id} class={"flex " <> (if msg.sender_id == @current_user.id, do: "justify-end", else: "justify-start")}>
                <div class={"max-w-md px-4 py-2 relative group " <> (if msg.sender_id == @current_user.id, do: "msg-own", else: "msg-other")}>
                  <div :if={msg.sender_id != @current_user.id} class="text-xs font-semibold text-accent-dim mb-0.5">
                    <%= msg.sender.display_name || msg.sender.username %>
                  </div>
                  <div :if={@editing_message_id != msg.id} class="text-sm whitespace-pre-wrap"><%= msg.body %></div>
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
            <form phx-submit="send-message" class="chat-input p-4 flex gap-3 bg-secondary/50">
              <input type="text" name="body" value={@new_message} placeholder="type a message..."
                class="input-field flex-1" />
              <button type="submit" class="btn btn-primary rounded-xl px-6 py-2 text-sm">
                Send
              </button>
            </form>
          </div>
        </main>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("select-conversation", %{"id" => id}, socket) do
    messages = Conversations.list_messages(id)

    {:noreply,
     socket
     |> assign(current_conversation_id: id, editing_message_id: nil, editing_body: "")
     |> stream(:messages, messages, reset: true)}
  end

  def handle_event("send-message", %{"body" => body}, socket) do
    body = String.trim(body)

    if body != "" and socket.assigns.current_conversation_id do
      case Conversations.send_message(
             socket.assigns.current_conversation_id,
             socket.assigns.current_user.id,
             body
           ) do
        {:ok, _msg} ->
          messages = Conversations.list_messages(socket.assigns.current_conversation_id)

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

      conversations = Conversations.list_conversations(socket.assigns.current_user.id)
      enriched = Conversations.enrich_conversations(conversations, socket.assigns.current_user.id)

      {:noreply,
       socket
       |> assign(conversations: enriched, current_conversation_id: nil)
       |> stream(:messages, [], reset: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("new-conversation", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/conversations/new")}
  end

  def handle_info({:new_message, _message}, socket) do
    if socket.assigns.current_conversation_id do
      messages = Conversations.list_messages(socket.assigns.current_conversation_id)
      {:noreply, stream(socket, :messages, messages, reset: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:conversation_updated, _conversation_id}, socket) do
    refresh_conversations(socket)
  end

  defp refresh_conversations(socket) do
    conversations = Conversations.list_conversations(socket.assigns.current_user.id)
    enriched = Conversations.enrich_conversations(conversations, socket.assigns.current_user.id)
    {:noreply, assign(socket, conversations: enriched)}
  end

  defp conversation_display_name(conv_id, conversations) do
    case Enum.find(conversations, fn c -> c.id == conv_id end) do
      nil -> ""
      conv -> conv.display_name
    end
  end

  defp format_time(nil), do: ""

  defp format_time(dt) do
    Calendar.strftime(dt, "%b %d %H:%M")
  end
end
