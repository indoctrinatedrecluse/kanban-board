require "application_system_test_case"

class KanbanCardDuplicationTest < ApplicationSystemTestCase
  setup do
    Board.destroy_all
    User.destroy_all

    @user = User.create!(name: "Test User", email: "test@example.test")
    @board = Board.create!(name: "Test Board")
    @column1 = @board.columns.create!(name: "To Do", position: 1)
    @column2 = @board.columns.create!(name: "Doing", position: 2)
    @card = @column1.cards.create!(
      title: "Test Card",
      priority: "high",
      description: "Test description",
      estimate: 5,
      labels: "bug,urgent",
      position: 1
    )
  end

  test "clear board button appears" do
    visit root_path

    assert_button "🗑️ Clear"
  end

  test "clear board shows confirmation" do
    visit root_path

    # Note: Capybara doesn't handle browser dialogs easily, 
    # but we can test that the button exists and has the correct onclick
    button = find(".menu-btn", text: /Clear/)
    assert button["onclick"].include?("confirm")
    assert button["onclick"].include?("/boards/clear")
  end

  test "settings button appears" do
    visit root_path

    assert_button "⚙️ Settings"
  end

  test "card is selectable and appears selected" do
    visit root_path

    card = find(".kanban-card", text: "Test Card")
    card.click

    assert card["class"].include?("is-selected")
  end
end
