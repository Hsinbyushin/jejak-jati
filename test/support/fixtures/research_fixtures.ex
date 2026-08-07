defmodule JejakJati.ResearchFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `JejakJati.Research` context.
  """

  @doc """
  Generate a research_run.
  """
  def research_run_fixture(attrs \\ %{}) do
    {:ok, research_run} =
      attrs
      |> Enum.into(%{
        author_name: "some author_name",
        isbn: "some isbn",
        status: :pending,
        title: "some title"
      })
      |> JejakJati.Research.create_research_run()

    research_run
  end
end
