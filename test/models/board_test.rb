require "test_helper"

class BoardTest < ActiveSupport::TestCase
  test "requires a name" do
    board = Board.new

    assert_not board.valid?
    assert_includes board.errors[:name], "can't be blank"
  end

  test "orders columns by position" do
    board = Board.create!(name: "Roadmap")
    later = board.columns.create!(name: "Later", position: 2)
    sooner = board.columns.create!(name: "Sooner", position: 1)

    assert_equal [sooner, later], board.reload.columns.to_a
  end
end
