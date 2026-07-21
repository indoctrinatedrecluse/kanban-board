require_relative "application_system_test_case"

class DragAndDropTest < ApplicationSystemTestCase
  setup do
    Board.destroy_all
    User.destroy_all

    @user = User.create!(name: "Avery Chen", email: "avery-test@example.test")
    @board = Board.create!(name: "Test Board")
    @todo = @board.columns.create!(name: "To Do", position: 1)
    @doing = @board.columns.create!(name: "Doing", position: 2)
    @card = @todo.cards.create!(title: "Move me", priority: "medium", assignee: @user, position: 1)
  end

  test "drag and drop a card to another column" do
    visit root_path

    source_card = find("#card_#{@card.id}")
    target_column = find("#column_#{@doing.id} .kanban-column-cards")

    source_card.drag_to(target_column)

    assert_equal @doing, @card.reload.column
  end
end