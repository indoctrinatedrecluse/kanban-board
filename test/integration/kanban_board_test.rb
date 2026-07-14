require "test_helper"

class KanbanBoardTest < ActionDispatch::IntegrationTest
  setup do
    Board.destroy_all
    User.destroy_all

    @user = User.create!(name: "Avery Chen", email: "avery-test@example.test")
    @board = Board.create!(name: "Test Board")
    @todo = @board.columns.create!(name: "To Do", position: 1)
    @doing = @board.columns.create!(name: "Doing", position: 2)
    @card = @todo.cards.create!(title: "Move me", priority: "medium", assignee: @user, position: 1)
  end

  test "renders the kanban board" do
    get root_path

    assert_response :success
    assert_select "h1", "Test Board"
    assert_select ".kanban-card h3", "Move me"
  end

  test "moves a card to another column and position" do
    patch move_card_path(@card), params: { column_id: @doing.id, position: 1 }

    assert_response :success
    @card.reload
    assert_equal @doing, @card.column
    assert_equal 1, @card.position
  end
end
