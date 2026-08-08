defmodule JejakJati.Bibliography.ISBNTest do
  use ExUnit.Case, async: true

  alias JejakJati.Bibliography.ISBN

  test "normalizes ISBN-13" do
    assert ISBN.normalize("978-983-2085-01-0") ==
             "9789832085010"
  end

  test "converts ISBN-10 to equivalent ISBN-13" do
    assert ISBN.normalize("9832085012") ==
             "9789832085010"
  end

  test "recognizes equivalent ISBN-10 and ISBN-13 values" do
    assert ISBN.equivalent?(
             "9832085012",
             "9789832085010"
           )
  end

  test "rejects unrelated ISBNs" do
    refute ISBN.equivalent?(
             "9832085012",
             "9781349317707"
           )
  end

  test "returns nil for invalid ISBN values" do
    assert ISBN.normalize("not-an-isbn") == nil
  end
end
