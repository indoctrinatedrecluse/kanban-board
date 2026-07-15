require "test_helper"

class BoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Board.destroy_all
    User.destroy_all

    @user = User.create!(name: "Test User", email: "test@example.test")
    @board = Board.create!(name: "Test Board", description: "Test Description")
    @todo = @board.columns.create!(name: "To Do", position: 1)
    @doing = @board.columns.create!(name: "Doing", position: 2, wip_limit: 3)
    @todo.cards.create!(title: "Card 1", priority: "medium", position: 1)
    @doing.cards.create!(title: "Card 2", priority: "high", assignee: @user, position: 1)
  end

  test "show renders the current board shell" do
    get root_path

    assert_response :success
    assert_select "h1#board_name", "Test Board"
    assert_select "p#board_description", "Test Description"
    assert_select ".board-stats", /2 cards/
    assert_select ".board-stats", /1 people/
    assert_select ".board-menu"
    assert_select ".menu-btn[data-modal-url=?]", edit_board_path, "Settings"
  end

  test "edit renders board settings modal" do
    get edit_board_path, headers: { "Accept": "text/html" }

    assert_response :success
    assert_select ".modal-header h2", "Board Settings"
    assert_select "input[name='board[name]'][value=?]", "Test Board"
    assert_select "textarea[name='board[description]']", "Test Description"
    assert_select ".stat-item", /Columns:.*2/
    assert_select ".stat-item", /Cards:.*2/
    assert_select ".stat-item", /WIP-limited columns:.*1/
  end

  test "update changes board settings and returns turbo stream" do
    patch board_path, params: {
      board: {
        name: "Updated Board",
        description: "Updated Description"
      }
    }, headers: { "Accept": "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_includes response.body, "target=\"board_name\""
    assert_includes response.body, "target=\"board_description\""

    @board.reload
    assert_equal "Updated Board", @board.name
    assert_equal "Updated Description", @board.description
  end

  test "clear removes cards while keeping columns" do
    assert_difference "Card.count", -2 do
      post clear_board_path
    end

    assert_redirected_to root_path
    assert_equal "Board cleared successfully", flash[:notice]
    assert_equal ["To Do", "Doing"], @board.reload.columns.map(&:name)
  end
end
