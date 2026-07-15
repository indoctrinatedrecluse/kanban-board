require "test_helper"

class CardTest < ActiveSupport::TestCase
  test "requires a title" do
    card = Card.new(column: columns(:one), priority: "medium")

    assert_not card.valid?
    assert_includes card.errors[:title], "can't be blank"
  end

  test "allows only known priorities" do
    card = cards(:one)

    card.priority = "blocked"

    assert_not card.valid?
    assert_includes card.errors[:priority], "is not included in the list"
  end

  test "parses comma separated labels" do
    card = Card.new(labels: " bug, feature, , urgent ")

    assert_equal ["bug", "feature", "urgent"], card.label_list
  end
end
