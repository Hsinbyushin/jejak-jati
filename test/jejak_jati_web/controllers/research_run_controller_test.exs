defmodule JejakJatiWeb.ResearchRunControllerTest do
  use JejakJatiWeb.ConnCase

  alias JejakJati.Research

  test "POST /research-runs creates a research run and redirects", %{conn: conn} do
    conn =
      post(conn, ~p"/research-runs", %{
        "research_run" => %{
          "title" => "In Search of Modernity",
          "author_name" => "Hadijah Rahmat",
          "isbn" => ""
        }
      })

    [research_run] = Research.list_research_runs()

    assert research_run.title == "In Search of Modernity"
    assert research_run.author_name == "Hadijah Rahmat"
    assert research_run.status == :pending

    assert redirected_to(conn) == ~p"/research-runs/#{research_run}"
  end

  test "GET /research-runs/:id shows the research run", %{conn: conn} do
    {:ok, research_run} =
      Research.create_research_run(%{
        title: "In Search of Modernity",
        author_name: "Hadijah Rahmat"
      })

    conn = get(conn, ~p"/research-runs/#{research_run}")

    html = html_response(conn, 200)

    assert html =~ "In Search of Modernity"
    assert html =~ "Hadijah Rahmat"
    assert html =~ "Ausstehend"
    assert html =~ research_run.id
  end

  test "GET /research-runs/:id shows source research results", %{conn: conn} do
    {:ok, research_run} =
      Research.create_research_run(%{
        title: "In Search of Modernity",
        author_name: "Hadijah Rahmat"
      })

    {:ok, _source_request} =
      Research.create_source_request(%{
        research_run_id: research_run.id,
        source: :dnb,
        status: :succeeded,
        candidate_count: 6,
        best_score: 14,
        decision: :no_match
      })

    conn =
      get(conn, ~p"/research-runs/#{research_run}")

    html = html_response(conn, 200)

    assert html =~ "Deutsche Nationalbibliothek"
    assert html =~ "Erfolgreich"
    assert html =~ "6"
    assert html =~ "14"
    assert html =~ "Kein belastbarer Treffer"
  end
end
