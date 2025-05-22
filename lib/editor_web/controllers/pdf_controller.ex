defmodule EditorWeb.PDFController do
  use EditorWeb, :controller

  def export(conn, %{"html" => html}) do
    html
    |> PdfGenerator.generate(page_size: "A4")
    |> handle_pdf_response(conn)
  end

  defp handle_pdf_response({:ok, pdf_content}, conn) do
    conn
    |> put_resp_content_type("application/pdf")
    |> put_resp_header("content-disposition", "attachment; filename=export.pdf")
    |> send_resp(200, pdf_content)
  end

  defp handle_pdf_response({:error, error}, conn) do
    conn
    |> put_flash(:error, "Failed to generate PDF: #{inspect(error)}")
    |> redirect(to: "/")
  end
end
