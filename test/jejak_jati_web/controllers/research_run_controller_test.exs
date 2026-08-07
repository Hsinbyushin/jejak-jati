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
end
