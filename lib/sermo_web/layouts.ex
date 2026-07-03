defmodule SermoWeb.Layouts do
  use SermoWeb, :html

  def app(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="h-full">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <title>Sermo</title>
        <script defer src={~p"/assets/phoenix.js"}></script>
        <script defer src={~p"/assets/phoenix_live_view.js"}></script>
        <script defer src={~p"/assets/phoenix_html.js"}></script>
        <script defer src={~p"/assets/app.js"}></script>
        <style>
          @font-face {
            font-family: 'Rosemary';
            src: url('/fonts/Rosemary.ttf') format('truetype');
            font-weight: normal;
            font-style: normal;
            font-display: swap;
          }

          :root {
            --vz-bg-primary: #050200;
            --vz-bg-secondary: #0f0a05;
            --vz-accent-vibrant: #FFB347;
            --vz-accent-muted: rgba(255, 179, 71, 0.6);
            --vz-glow-color: rgba(255, 179, 71, 0.8);
            --vz-gradient-1: #FFB347;
            --vz-gradient-2: #D72638;
            --vz-gradient-3: #FFB347;
            --vz-border-color: rgba(255, 179, 71, 0.15);
            --vz-text-color-secondary: #d1d5db;
            --vz-card-bg: rgba(15, 10, 5, 0.6);
            --vz-card-border: rgba(255, 179, 71, 0.12);

            font-family: Rosemary, system-ui, sans-serif;
            color-scheme: dark;
            color: #f3f4f6;
            background-color: #000;
          }

          * { margin: 0; padding: 0; box-sizing: border-box; }
          html, body { height: 100%; background: var(--vz-bg-primary); color: #f3f4f6; }
          body { overflow: hidden; }

          ::-webkit-scrollbar { width: 8px; }
          ::-webkit-scrollbar-track { background: var(--vz-bg-primary); }
          ::-webkit-scrollbar-thumb { background: var(--vz-accent-vibrant); border-radius: 4px; }
          ::-webkit-scrollbar-thumb:hover { background: var(--vz-gradient-2); }

          .flash-info, .flash-error {
            padding: 0.75rem 1rem;
            text-align: center;
            font-size: 0.875rem;
            backdrop-filter: blur(12px);
            border-bottom: 1px solid var(--vz-border-color);
          }
          .flash-info { background: rgba(255, 179, 71, 0.08); color: var(--vz-accent-vibrant); }
          .flash-error { background: rgba(215, 38, 56, 0.12); color: #fca5a5; }

          /* Layout */
          .flex { display: flex; }
          .flex-col { flex-direction: column; }
          .flex-1 { flex: 1; }
          .flex-2 { flex: 2; }
          .h-full { height: 100%; }
          .items-center { align-items: center; }
          .items-start { align-items: flex-start; }
          .justify-center { justify-content: center; }
          .justify-between { justify-content: space-between; }
          .justify-start { justify-content: flex-start; }
          .justify-end { justify-content: flex-end; }
          .w-full { width: 100%; }
          .w-72 { width: 18rem; }
          .max-w-sm { max-width: 24rem; }
          .max-w-md { max-width: 28rem; }
          .max-w-lg { max-width: 32rem; }
          .max-w-xl { max-width: 36rem; }
          .mx-auto { margin-left: auto; margin-right: auto; }
          .mx-4 { margin-left: 1rem; margin-right: 1rem; }
          .mb-6 { margin-bottom: 1.5rem; }
          .mb-0\\.5 { margin-bottom: 0.125rem; }
          .mt-1 { margin-top: 0.25rem; }
          .mt-4 { margin-top: 1rem; }
          .ml-2 { margin-left: 0.5rem; }
          .p-3 { padding: 0.75rem; }
          .p-4 { padding: 1rem; }
          .p-6 { padding: 1.5rem; }
          .p-8 { padding: 2rem; }
          .px-3 { padding-left: 0.75rem; padding-right: 0.75rem; }
          .px-4 { padding-left: 1rem; padding-right: 1rem; }
          .px-6 { padding-left: 1.5rem; padding-right: 1.5rem; }
          .px-8 { padding-left: 2rem; padding-right: 2rem; }
          .py-1\\.5 { padding-top: 0.375rem; padding-bottom: 0.375rem; }
          .py-2 { padding-top: 0.5rem; padding-bottom: 0.5rem; }
          .py-3 { padding-top: 0.75rem; padding-bottom: 0.75rem; }
          .py-4 { padding-top: 1rem; padding-bottom: 1rem; }
          .gap-2 { gap: 0.5rem; }
          .gap-3 { gap: 0.75rem; }
          .gap-4 { gap: 1rem; }
          .gap-6 { gap: 1.5rem; }
          .space-y-1 > * + * { margin-top: 0.25rem; }
          .space-y-2 > * + * { margin-top: 0.5rem; }
          .space-y-3 > * + * { margin-top: 0.75rem; }
          .space-y-4 > * + * { margin-top: 1rem; }
          .space-y-6 > * + * { margin-top: 1.5rem; }
          .min-w-0 { min-width: 0; }

          /* Borders */
          .border { border: 1px solid var(--vz-border-color); }
          .border-r { border-right: 1px solid var(--vz-border-color); }
          .border-t { border-top: 1px solid var(--vz-border-color); }
          .border-b { border-bottom: 1px solid var(--vz-border-color); }
          .border-l-2 { border-left-width: 2px; }
          .border-l-accent { border-left-color: var(--vz-accent-vibrant); }
          .border-l-transparent { border-left-color: transparent; }

          /* Border radius */
          .rounded { border-radius: 0.5rem; }
          .rounded-lg { border-radius: 0.75rem; }
          .rounded-xl { border-radius: 1rem; }
          .rounded-2xl { border-radius: 1.25rem; }
          .rounded-3xl { border-radius: 1.5rem; }
          .rounded-full { border-radius: 9999px; }
          .cover { width: 100%; height: 100%; object-fit: cover; }

          /* Backgrounds */
          .bg-primary { background-color: var(--vz-bg-primary); }
          .bg-secondary { background-color: var(--vz-bg-secondary); }
          .bg-accent { background-color: var(--vz-accent-vibrant); }
          .bg-accent-subtle { background-color: rgba(255, 179, 71, 0.08); }
          .bg-accent-active { background-color: rgba(255, 179, 71, 0.12); }
          .bg-secondary\\/50 { background-color: rgba(15, 10, 5, 0.5); }
          .bg-accent\\/10 { background-color: rgba(255, 179, 71, 0.1); }
          .bg-accent\\/30 { background-color: rgba(255, 179, 71, 0.3); }
          .hover\\:bg-accent-subtle:hover { background-color: rgba(255, 179, 71, 0.08); }
          .hover\\:bg-accent-active:hover { background-color: rgba(255, 179, 71, 0.15); }

          /* Text colors */
          .text-white { color: #f3f4f6; }
          .text-muted { color: #6b7280; }
          .text-secondary { color: var(--vz-text-color-secondary); }
          .text-accent { color: var(--vz-accent-vibrant); }
          .text-accent-dim { color: rgba(255, 179, 71, 0.6); }
          .text-gradient {
            background: linear-gradient(135deg, var(--vz-gradient-1), var(--vz-gradient-2), var(--vz-gradient-3));
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
          }

          /* Typography */
          .text-xs { font-size: 0.75rem; }
          .text-sm { font-size: 0.875rem; }
          .text-lg { font-size: 1.125rem; }
          .text-xl { font-size: 1.25rem; }
          .text-2xl { font-size: 1.5rem; }
          .text-3xl { font-size: 1.875rem; }
          .text-4xl { font-size: 2.25rem; }
          .text-5xl { font-size: 3rem; }
          .text-red-400 { color: #f87171; }
          .text-green-400 { color: #4ade80; }
          .text-black\\/60 { color: rgba(0, 0, 0, 0.6); }
          .font-medium { font-weight: 500; }
          .font-semibold { font-weight: 600; }
          .font-bold { font-weight: 700; }
          .font-black { font-weight: 900; }
          .font-mono { font-family: ui-monospace, monospace; }
          .text-center { text-align: center; }
          .text-right { text-align: right; }
          .underline { text-decoration: underline; }
          .no-underline { text-decoration: none; }
          .truncate { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
          .whitespace-pre-wrap { white-space: pre-wrap; }
          .select-all { user-select: all; }
          .tracking-wide { letter-spacing: 0.025em; }
          .tracking-wider { letter-spacing: 0.05em; }
          .tracking-widest { letter-spacing: 0.1em; }
          .uppercase { text-transform: uppercase; }
          .italic { font-style: italic; }
          .leading-relaxed { line-height: 1.625; }

          /* Overflow & display */
          .overflow-y-auto { overflow-y: auto; }
          .overflow-x-hidden { overflow-x: hidden; }
          .resize-none { resize: none; }
          .shrink-0 { flex-shrink: 0; }
          .inline-block { display: inline-block; }
          .cursor-pointer { cursor: pointer; }
          .cursor-default { cursor: default; }
          .select-none { user-select: none; }
          .opacity-0 { opacity: 0; }
          .group:hover .group-hover\\:opacity-100 { opacity: 1; }
          .group:hover .group-hover\\:text-white { color: #f3f4f6; }
          .transition { transition: all 0.2s ease; }
          .transition-fast { transition: all 0.1s ease; }

          /* Shadows & effects */
          .shadow-glow { box-shadow: 0 0 25px var(--vz-glow-color); }
          .shadow-glow-sm { box-shadow: 0 0 12px var(--vz-glow-color); }
          .shadow-card { box-shadow: 0 0 30px rgba(0,0,0,0.3); }
          .hover-glow:hover { box-shadow: 0 0 25px var(--vz-glow-color); }
          .hover-scale:hover { transform: scale(1.02); }
          .hover-bright:hover { filter: brightness(1.15); }
          .backdrop-blur { backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px); }
          .backdrop-blur-sm { backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px); }

          @keyframes shimmer {
            0% { transform: translateX(-100%); }
            100% { transform: translateX(100%); }
          }

          /* Sidebar */
          .sidebar-item {
            padding: 0.75rem;
            border-bottom: 1px solid var(--vz-border-color);
            border-left: 2px solid transparent;
            cursor: pointer;
            transition: all 0.2s ease;
          }
          .sidebar-item:hover { background: rgba(255, 179, 71, 0.04); }
          .sidebar-item.active {
            background: rgba(255, 179, 71, 0.08);
            border-left-color: var(--vz-accent-vibrant);
          }

          /* Buttons */
          .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-family: inherit;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s ease;
            border: 1px solid transparent;
            user-select: none;
          }
          .btn-primary {
            background: linear-gradient(135deg, var(--vz-gradient-1), var(--vz-gradient-2));
            color: #000;
            border: none;
          }
          .btn-primary:hover {
            box-shadow: 0 0 25px var(--vz-glow-color);
            transform: scale(1.02);
            filter: brightness(1.1);
          }
          .btn-primary:active { transform: scale(0.97); }
          .btn-ghost {
            background: transparent;
            color: var(--vz-accent-vibrant);
            border: 1px solid var(--vz-accent-muted);
          }
          .btn-ghost:hover {
            background: rgba(255, 179, 71, 0.08);
            border-color: var(--vz-accent-vibrant);
          }
          .btn-ghost:active { transform: scale(0.97); }

          /* Form elements */
          .input-field {
            width: 100%;
            background: rgba(0, 0, 0, 0.5);
            border: 1px solid var(--vz-border-color);
            border-radius: 1rem;
            padding: 0.75rem 1rem;
            font-size: 0.875rem;
            font-family: inherit;
            color: #f3f4f6;
            outline: none;
            transition: all 0.2s ease;
          }
          .input-field:focus {
            border-color: var(--vz-accent-vibrant);
            box-shadow: 0 0 15px rgba(255, 179, 71, 0.2);
          }
          .input-field::placeholder { color: #6b7280; }

          .select-field {
            width: 100%;
            background: rgba(0, 0, 0, 0.5);
            border: 1px solid var(--vz-border-color);
            border-radius: 1rem;
            padding: 0.75rem 1rem;
            font-size: 0.875rem;
            font-family: inherit;
            color: #f3f4f6;
            outline: none;
            transition: all 0.2s ease;
            cursor: pointer;
          }
          .select-field:focus {
            border-color: var(--vz-accent-vibrant);
            box-shadow: 0 0 15px rgba(255, 179, 71, 0.2);
          }
          .select-field option { background: #0f0a05; color: #f3f4f6; }

          .label {
            color: var(--vz-text-color-secondary);
            font-size: 0.75rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.08em;
          }

          /* Cards */
          .card {
            background: var(--vz-card-bg);
            backdrop-filter: blur(16px);
            border: 1px solid var(--vz-card-border);
            border-radius: 1.5rem;
            transition: all 0.3s ease;
            box-shadow: 0 0 30px rgba(0,0,0,0.2);
          }
          .card:hover {
            box-shadow: 0 0 40px var(--vz-glow-color);
            transform: translateY(-2px);
            border-color: rgba(255, 179, 71, 0.25);
          }

          /* Messages */
          .msg-own {
            background: linear-gradient(135deg, var(--vz-gradient-1), var(--vz-gradient-2));
            color: #000;
            border-radius: 1.25rem 1.25rem 0.25rem 1.25rem;
          }
          .msg-other {
            background: rgba(15, 10, 5, 0.8);
            backdrop-filter: blur(8px);
            border: 1px solid var(--vz-border-color);
            border-radius: 1.25rem 1.25rem 1.25rem 0.25rem;
          }

          /* Chat chrome */
          .sidebar-header {
            border-bottom: 1px solid var(--vz-border-color);
            backdrop-filter: blur(16px);
          }
          .sidebar-footer {
            border-top: 1px solid var(--vz-border-color);
            backdrop-filter: blur(16px);
          }
          .chat-input {
            border-top: 1px solid var(--vz-border-color);
            backdrop-filter: blur(16px);
          }
          .chat-header {
            backdrop-filter: blur(16px);
          }

          @media (min-width: 1024px) {
            .lg\\:w-80 { width: 20rem; }
            .lg\\:max-w-xl { max-width: 36rem; }
            .lg\\:max-w-2xl { max-width: 42rem; }
            .lg\\:max-w-4xl { max-width: 56rem; }
            .lg\\:max-w-5xl { max-width: 64rem; }
            .lg\\:msg-max { max-width: 36rem; }
            .lg\\:grid { display: grid; }
            .lg\\:grid-cols-2 { grid-template-columns: repeat(2, 1fr); }
          }
        </style>
      </head>
      <body>
        <div :if={info = Phoenix.Flash.get(@flash, :info)} class="flash-info"><%= info %></div>
        <div :if={err = Phoenix.Flash.get(@flash, :error)} class="flash-error"><%= err %></div>
        <%= render_slot(@inner_block) %>
      </body>
    </html>
    """
  end
end
