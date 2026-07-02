defmodule SermoWeb.Layouts do
  use SermoWeb, :html

  def app(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="h-full">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Sermo</title>
        <style>
          @font-face {
            font-family: 'Rosemary';
            src: url('/fonts/Rosemary.ttf') format('truetype');
            font-weight: normal;
            font-style: normal;
            font-display: swap;
          }

          :root {
            --vz-bg-primary: #080000;
            --vz-bg-secondary: #1a0808;
            --vz-accent-vibrant: #ef4444;
            --vz-accent-muted: rgba(239, 68, 68, 0.6);
            --vz-glow-color: rgba(220, 38, 38, 0.8);
            --vz-gradient-1: #ef4444;
            --vz-gradient-2: #7f1d1d;
            --vz-gradient-3: #ef4444;
            --vz-border-color: rgba(220, 38, 38, 0.2);
            --vz-text-color-secondary: #f87171;
            --vz-card-bg: var(--vz-bg-secondary);
            --vz-card-border: rgba(239, 68, 68, 0.4);

            font-family: Rosemary, system-ui, sans-serif;
            color-scheme: dark;
            color: #f3f4f6;
            background-color: #000;
          }

          * { margin: 0; padding: 0; box-sizing: border-box; }
          html, body { height: 100%; background: var(--vz-bg-primary); color: #f3f4f6; }
          body { overflow: hidden; }

          ::-webkit-scrollbar { width: 6px; }
          ::-webkit-scrollbar-track { background: var(--vz-bg-primary); }
          ::-webkit-scrollbar-thumb { background: var(--vz-accent-vibrant); border-radius: 3px; }
          ::-webkit-scrollbar-thumb:hover { background: var(--vz-gradient-2); }

          .flash-info {
            background: rgba(239, 68, 68, 0.1);
            color: var(--vz-accent-vibrant);
            padding: 0.75rem 1rem;
            text-align: center;
            font-size: 0.875rem;
            border-bottom: 1px solid var(--vz-border-color);
            backdrop-filter: blur(8px);
          }
          .flash-error {
            background: rgba(220, 38, 38, 0.15);
            color: #fca5a5;
            padding: 0.75rem 1rem;
            text-align: center;
            font-size: 0.875rem;
            border-bottom: 1px solid rgba(220, 38, 38, 0.4);
            backdrop-filter: blur(8px);
          }

          .flex { display: flex; }
          .flex-col { flex-direction: column; }
          .flex-1 { flex: 1; }
          .h-full { height: 100%; }
          .items-center { align-items: center; }
          .justify-center { justify-content: center; }
          .justify-between { justify-content: space-between; }
          .justify-start { justify-content: flex-start; }
          .justify-end { justify-content: flex-end; }
          .w-full { width: 100%; }
          .w-72 { width: 18rem; }
          .max-w-sm { max-width: 24rem; }
          .max-w-md { max-width: 28rem; }
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
          .space-y-1 > * + * { margin-top: 0.25rem; }
          .space-y-2 > * + * { margin-top: 0.5rem; }
          .space-y-3 > * + * { margin-top: 0.75rem; }
          .space-y-4 > * + * { margin-top: 1rem; }
          .space-y-6 > * + * { margin-top: 1.5rem; }

          .border { border: 1px solid var(--vz-border-color); }
          .border-r { border-right: 1px solid var(--vz-border-color); }
          .border-t { border-top: 1px solid var(--vz-border-color); }
          .border-b { border-bottom: 1px solid var(--vz-border-color); }
          .border-l-4 { border-left-width: 4px; }
          .border-l-accent { border-left-color: var(--vz-accent-vibrant); }
          .border-l-transparent { border-left-color: transparent; }

          .rounded { border-radius: 0.5rem; }
          .rounded-lg { border-radius: 0.75rem; }
          .rounded-xl { border-radius: 1rem; }
          .rounded-2xl { border-radius: 1.25rem; }
          .rounded-full { border-radius: 9999px; }

          .bg-primary { background-color: var(--vz-bg-primary); }
          .bg-secondary { background-color: var(--vz-bg-secondary); }
          .bg-accent { background-color: var(--vz-accent-vibrant); }
          .bg-accent-subtle { background-color: rgba(239, 68, 68, 0.1); }
          .bg-accent-active { background-color: rgba(239, 68, 68, 0.15); }

          .text-white { color: #f3f4f6; }
          .text-muted { color: #6b7280; }
          .text-secondary { color: var(--vz-text-color-secondary); }
          .text-accent { color: var(--vz-accent-vibrant); }
          .text-accent-dim { color: rgba(239, 68, 68, 0.6); }
          .text-gradient {
            background: linear-gradient(135deg, var(--vz-gradient-1), var(--vz-gradient-2), var(--vz-gradient-3));
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
          }

          .text-xs { font-size: 0.75rem; }
          .text-sm { font-size: 0.875rem; }
          .text-lg { font-size: 1.125rem; }
          .text-xl { font-size: 1.25rem; }
          .text-2xl { font-size: 1.5rem; }
          .text-3xl { font-size: 1.875rem; }
          .font-medium { font-weight: 500; }
          .font-semibold { font-weight: 600; }
          .font-bold { font-weight: 700; }
          .font-black { font-weight: 900; }
          .text-center { text-align: center; }
          .underline { text-decoration: underline; }
          .whitespace-pre-wrap { white-space: pre-wrap; }
          .overflow-y-auto { overflow-y: auto; }
          .overflow-x-hidden { overflow-x: hidden; }
          .cursor-pointer { cursor: pointer; }
          .select-none { user-select: none; }
          .transition { transition: all 0.2s ease; }
          .transition-fast { transition: all 0.1s ease; }

          .shadow-glow { box-shadow: 0 0 20px var(--vz-glow-color); }
          .shadow-glow-sm { box-shadow: 0 0 10px var(--vz-glow-color); }
          .hover-glow:hover { box-shadow: 0 0 20px var(--vz-glow-color); }
          .hover-scale:hover { transform: scale(1.02); }
          .hover-bright:hover { filter: brightness(1.2); }
          .backdrop-blur { backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); }

          .sidebar-item {
            padding: 0.75rem;
            border-bottom: 1px solid var(--vz-border-color);
            border-left: 4px solid transparent;
            cursor: pointer;
            transition: all 0.2s ease;
          }
          .sidebar-item:hover { background-color: rgba(239, 68, 68, 0.05); }
          .sidebar-item.active {
            background-color: rgba(239, 68, 68, 0.12);
            border-left-color: var(--vz-accent-vibrant);
          }

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
            background-color: var(--vz-accent-vibrant);
            color: #000;
            border-color: var(--vz-accent-vibrant);
          }
          .btn-primary:hover {
            background-color: #dc2626;
            box-shadow: 0 0 20px var(--vz-glow-color);
            transform: scale(1.02);
          }
          .btn-ghost {
            background: transparent;
            color: var(--vz-accent-vibrant);
            border-color: var(--vz-accent-muted);
          }
          .btn-ghost:hover {
            background: rgba(239, 68, 68, 0.1);
            border-color: var(--vz-accent-vibrant);
          }
          .btn-ghost:active { transform: scale(0.97); }

          .input-field {
            width: 100%;
            background: rgba(0, 0, 0, 0.4);
            border: 1px solid var(--vz-border-color);
            border-radius: 0.75rem;
            padding: 0.625rem 1rem;
            font-size: 0.875rem;
            font-family: inherit;
            color: #f3f4f6;
            outline: none;
            transition: all 0.2s ease;
          }
          .input-field:focus {
            border-color: var(--vz-accent-vibrant);
            box-shadow: 0 0 12px rgba(239, 68, 68, 0.25);
          }
          .input-field::placeholder { color: #6b7280; }

          .select-field {
            width: 100%;
            background: rgba(0, 0, 0, 0.4);
            border: 1px solid var(--vz-border-color);
            border-radius: 0.75rem;
            padding: 0.625rem 1rem;
            font-size: 0.875rem;
            font-family: inherit;
            color: #f3f4f6;
            outline: none;
            transition: all 0.2s ease;
            cursor: pointer;
          }
          .select-field:focus {
            border-color: var(--vz-accent-vibrant);
            box-shadow: 0 0 12px rgba(239, 68, 68, 0.25);
          }
          .select-field option { background: #1a0808; color: #f3f4f6; }

          .label { color: var(--vz-text-color-secondary); font-size: 0.875rem; font-weight: 500; }

          .card {
            background: var(--vz-card-bg);
            border: 1px solid var(--vz-card-border);
            border-radius: 1.25rem;
            transition: all 0.3s ease;
          }
          .card:hover {
            box-shadow: 0 0 35px var(--vz-glow-color);
            transform: translateY(-2px);
          }

          .msg-own {
            background: var(--vz-accent-vibrant);
            color: #000;
            border-radius: 1rem 1rem 0.25rem 1rem;
          }
          .msg-other {
            background: var(--vz-bg-secondary);
            border: 1px solid var(--vz-border-color);
            border-radius: 1rem 1rem 1rem 0.25rem;
          }

          .sidebar-header {
            border-bottom: 1px solid var(--vz-border-color);
            backdrop-filter: blur(12px);
          }
          .sidebar-footer {
            border-top: 1px solid var(--vz-border-color);
            backdrop-filter: blur(12px);
          }

          .chat-input {
            border-top: 1px solid var(--vz-border-color);
            backdrop-filter: blur(12px);
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
