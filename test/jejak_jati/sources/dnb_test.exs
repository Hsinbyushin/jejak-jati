defmodule JejakJati.Sources.DNBTest do
  use ExUnit.Case, async: true

  alias JejakJati.Sources.DNB

  setup do
    Req.Test.verify_on_exit!()

    :ok
  end

  test "normalizes DNB MARC21 results" do
    xml =
      File.read!("test/fixtures/dnb/search_response.xml")

    Req.Test.stub(DNB, fn conn ->
      Req.Test.text(conn, xml)
    end)

    assert {:ok, [result]} =
             DNB.search_work(
               "In Search of Modernity",
               "Hadijah Rahmat"
             )

    assert result.source == :dnb
    assert result.source_id == "123456789"
    assert result.title == "In Search of Modernity"
    assert result.author_name == "Rahmat, Hadijah"
    assert result.isbn == "9789832085010"
    assert result.publication_year == "2001"
    assert result.publisher == "University of Malaya Press"
    assert result.source_url == "https://d-nb.info/123456789"
  end
end
