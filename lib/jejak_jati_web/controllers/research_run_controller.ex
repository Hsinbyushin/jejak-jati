defmodule JejakJatiWeb.ResearchRunController do
  use JejakJatiWeb, :controller

  alias JejakJati.Research

  def create(conn, %{"research_run" => params}) do
    case Research.create_research_run(params) do
      {:ok, research_run} ->
        conn
        |> put_flash(:info, "Recherche wurde angelegt.")
        |> redirect(to: ~p"/research-runs/#{research_run}")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(JejakJatiWeb.PageHTML)
        |> render(:home, research_form: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    research_run = Research.get_research_run!(id)

    source_requests =
      Research.list_source_requests_for_run(research_run.id)

    render(conn, :show,
      research_run: research_run,
      source_requests: source_requests
    )
  end

  def sources_fragment(conn, %{"id" => id}) do
    research_run = Research.get_research_run!(id)

    source_requests =
      Research.list_source_requests_for_run(research_run.id)

    render(conn, :sources_fragment,
      layout: false,
      research_run: research_run,
      source_requests: source_requests
    )
  end
end
