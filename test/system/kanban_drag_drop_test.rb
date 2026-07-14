require "application_system_test_case"

class KanbanDragDropTest < ApplicationSystemTestCase
  setup do
    Board.destroy_all
    User.destroy_all

    @user = User.create!(name: "Test User", email: "test@example.test")
    @board = Board.create!(name: "Test Board")
    @todo = @board.columns.create!(name: "To Do", position: 1)
    @doing = @board.columns.create!(name: "Doing", position: 2)
    @card1 = @todo.cards.create!(title: "Card 1", priority: "medium", position: 1)
    @card2 = @todo.cards.create!(title: "Card 2", priority: "high", position: 2)
  end

  test "visiting the board" do
    visit root_path

    assert_selector "h1", text: "Test Board"
    assert_selector ".kanban-card h3", text: "Card 1"
    assert_selector ".kanban-card h3", text: "Card 2"
  end

  test "card selection with click" do
    visit root_path

    card = find(".kanban-card", text: "Card 1")
    card.click

    assert card["class"].include?("is-selected")
  end

  test "selecting a card deselects previous selection" do
    visit root_path

    card1 = find(".kanban-card", text: "Card 1")
    card2 = find(".kanban-card", text: "Card 2")

    card1.click
    assert card1["class"].include?("is-selected")

    card2.click
    assert_not card1["class"].include?("is-selected")
    assert card2["class"].include?("is-selected")
  end

  test "menu bar displays keyboard hints" do
    visit root_path

    assert_text "Ctrl+C"
    assert_text "Ctrl+V"
  end

  test "menu bar displays buttons" do
    visit root_path

    assert_button "🗑️ Clear"
    assert_button "⚙️ Settings"
  end

  test "board stats display correct count" do
    visit root_path

    assert_text "2 cards"
    assert_text "1 people"
  end
end
