defmodule JejakJati.Sources.Orchestrator do
  @moduledoc """
  Coordinates bibliographic source adapters for a research run.

  The orchestrator knows which bibliographic sources are available and invokes
  them through the shared `BibliographicSource` behaviour.

  It deliberately does not perform persistence or candidate matching. Its
  responsibility is limited to running source adapters and returning their
  normalized results.

  Keeping orchestration separate from workers means that Oban remains an
  execution mechanism rather than becoming the place where research logic
  accumulates.
  """

  alias JejakJati.Research.ResearchRun

  @default_sources [
    JejakJati.Sources.DNB
  ]

  @doc """
  Executes all configured bibliographic sources for a research run.

  Each result preserves the source module, source identifier, and the outcome
  of the source query.

  Example:

      [
        %{
          source: :dnb,
          adapter: JejakJati.Sources.DNB,
          result: {:ok, [...]}
        }
      ]
  """
  def search(%ResearchRun{} = research_run, sources \\ @default_sources) do
    Enum.map(sources, fn source ->
      %{
        source: source.source_name(),
        adapter: source,
        result:
          source.search_work(
            research_run.title,
            research_run.author_name
          )
      }
    end)
  end
end
