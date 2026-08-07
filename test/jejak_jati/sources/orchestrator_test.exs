defmodule JejakJati.Sources.OrchestratorTest do
  use ExUnit.Case, async: true

  alias JejakJati.Research.ResearchRun
  alias JejakJati.Sources.Orchestrator
  alias JejakJati.Sources.WorkResult

  defmodule FakeSource do
    @behaviour JejakJati.Sources.BibliographicSource

    @impl true
    def source_name, do: :fake

    @impl true
    def search_work(title, author_name) do
      {:ok,
       [
         %WorkResult{
           source: :fake,
           source_id: "fake-1",
           title: title,
           author_name: author_name
         }
       ]}
    end
  end

  test "runs configured bibliographic sources" do
    research_run = %ResearchRun{
      title: "In Search of Modernity",
      author_name: "Hadijah Rahmat"
    }

    assert [
             %{
               source: :fake,
               adapter: FakeSource,
               result: {:ok, [result]}
             }
           ] = Orchestrator.search(research_run, [FakeSource])

    assert result.source == :fake
    assert result.title == "In Search of Modernity"
    assert result.author_name == "Hadijah Rahmat"
  end
end
