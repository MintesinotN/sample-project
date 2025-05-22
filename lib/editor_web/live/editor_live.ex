defmodule EditorWeb.EditorLive do
  use EditorWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, markdown: "## Start typing here...", html: "", copied: false)}
  end

  def handle_event("update_markdown", %{"content" => markdown}, socket) do
    html = convert_to_html(markdown)
    {:noreply, assign(socket, markdown: markdown, html: html, copied: false)}
  end

  def handle_event("export_pdf", _params, socket) do
    case PdfGenerator.generate(socket.assigns.html,
           page_size: "A4",
           encoding: "UTF-8",
           delete_temporary: true
         ) do
      {:ok, pdf_content} ->
        {:noreply,
         socket
         |> push_event("download-pdf", %{
           content: Base.encode64(pdf_content),
           filename: "markdown-export-#{Date.utc_today()}.pdf"
         })}

      {:error, error} ->
        {:noreply,
         put_flash(socket, :error, "PDF generation failed: #{inspect(error)}")}
    end
  end

  def handle_event("copy_to_clipboard", _params, socket) do
    {:noreply,
     socket
     |> assign(copied: true)
     |> push_event("copy-html", %{html: socket.assigns.html})}
  end

  def handle_event("reset_copy", _params, socket) do
    {:noreply, assign(socket, copied: false)}
  end

  defp convert_to_html(markdown) do
    case Earmark.as_html(markdown, %Earmark.Options{
      code_class_prefix: "language-",
      gfm: true,
      breaks: true,
      smartypants: true
    }) do
      {:ok, html, _} -> html
        |> String.replace(~r/<h1>/, "<h1 class='text-3xl font-bold mt-6 mb-4'>")
        |> String.replace(~r/<h2>/, "<h2 class='text-2xl font-bold mt-5 mb-3'>")
        |> String.replace(~r/<h3>/, "<h3 class='text-xl font-bold mt-4 mb-2'>")
      {:error, error, _} -> "<p class='text-red-500'>Error: #{inspect(error)}</p>"
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <!-- Left pane - Markdown input -->
      <div class="w-1/2 p-4 bg-gray-50 border-r">
        <form phx-change="update_markdown" class="h-full flex flex-col">
          <div class="mb-2 text-sm font-mono text-gray-500">Markdown Input</div>
          <textarea
            name="content"
            class="flex-grow w-full p-4 font-mono text-gray-800 border rounded-lg resize-none focus:ring-2 focus:ring-blue-300"
            phx-debounce="200"
          ><%= @markdown %></textarea>
        </form>
      </div>

      <!-- Right pane - HTML output -->
      <div class="w-1/2 p-4 overflow-auto bg-white">
        <div class="flex justify-between items-center mb-2">
          <div class="text-sm font-mono text-gray-500">Rendered Output</div>
          <button
            phx-click="copy_to_clipboard"
            phx-hook="CopyButton"
            class="px-3 py-1 text-sm bg-blue-100 hover:bg-blue-200 rounded-lg transition-colors"
            id="copy-button"
          >
            <%= if @copied do %>
              <span class="text-green-600">✓ Copied!</span>
            <% else %>
              Copy
            <% end %>
          </button>
          <button
              phx-click="export_pdf"
              id="export-pdf"
              class="px-3 py-1 text-sm bg-green-100 hover:bg-green-200 rounded-lg transition-colors"
            >
              Export PDF
            </button>
        </div>
        <div
          id="rendered-output"
          class="prose max-w-none p-4 border rounded-lg min-h-full"
        >
          <%= if @html != "" do %>
            <%= raw(@html) %>
          <% else %>
            <div class="text-gray-400 italic">
              Your rendered content will appear here...
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
