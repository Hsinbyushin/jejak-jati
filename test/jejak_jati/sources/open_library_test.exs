defmodule JejakJati.Sources.OpenLibraryTest do
  use ExUnit.Case, async: true

  alias JejakJati.Sources.OpenLibrary

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  test "identifies itself as the Open Library source" do
    assert OpenLibrary.source_name() == :open_library
  end

  test "normalizes Open Library search results" do
    body =
      "test/fixtures/open_library/search_response.json"
      |> File.read!()
      |> Jason.decode!()

    Req.Test.stub(OpenLibrary, fn conn ->
      Req.Test.json(conn, body)
    end)

    assert {:ok, [result]} =
             OpenLibrary.search_work(
               "In Search of Modernity",
               "Hadijah Rahmat"
             )

    assert result.source == :open_library
    assert result.source_id == "OL123456W"
    assert result.title == "In Search of Modernity"
    assert result.author_name == "Hadijah Rahmat"
    assert result.isbn == "9789832085010"
    assert result.publication_year == "2001"
    assert result.publisher == "University of Malaya Press"
    assert result.source_url == "https://openlibrary.org/works/OL123456W"
  end
end
