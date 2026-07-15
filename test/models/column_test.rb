require "test_helper"

class ColumnTest < ActiveSupport::TestCase
  test "requires a name" do
    column = Column.new(board: boards(:one))

    assert_not column.valid?
    assert_includes column.errors[:name], "can't be blank"
  end

  test "orders cards by position" do
    board = Board.create!(name: "Roadmap")
    column = board.columns.create!(name: "Doing", position: 1)
    later = column.cards.create!(title: "Later", position: 2)
    sooner = column.cards.create!(title: "Sooner", position: 1)

    assert_equal [sooner, later], column.reload.cards.to_a
  end
end
