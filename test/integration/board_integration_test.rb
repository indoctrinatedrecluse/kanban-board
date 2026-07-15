require "test_helper"

class BoardIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    Board.destroy_all
    User.destroy_all

    @user = User.create!(name: "Avery Chen", email: "avery-test@example.test")
    @board = Board.create!(name: "Test Board")
    @todo = @board.columns.create!(name: "To Do", position: 1)
    @doing = @board.columns.create!(name: "Doing", position: 2)
    @card = @todo.cards.create!(title: "Move me", priority: "medium", assignee: @user, position: 1)
  end

  # Basic rendering tests
  test "renders the kanban board" do
    get root_path

    assert_response :success
    assert_select "h1", "Test Board"
    assert_select "body[data-controller=?]", "modal"
    assert_select "article#column_#{@todo.id}"
    assert_select ".kanban-card h3", "Move me"
  end

  test "renders card and column edit controls" do
    get root_path

    assert_response :success
    assert_select ".card-edit-btn[data-card-id=?]", @card.id.to_s
    assert_select ".column-edit-btn[data-column-id=?]", @todo.id.to_s
    assert_select ".menu-btn[data-modal-url=?]", edit_board_path
  end

  test "displays menu bar with keyboard hints" do
    get root_path

    assert_response :success
    assert_select ".board-menu"
    assert_select ".keyboard-hint", /Ctrl\+C/
    assert_select ".keyboard-hint", /Ctrl\+V/
  end

  test "displays menu buttons" do
    get root_path

    assert_response :success
    assert_select ".menu-btn", count: 2
    assert_select ".menu-btn", "Clear"
    assert_select ".menu-btn", "Settings"
  end

  test "can fetch board settings modal" do
    @board.update!(description: "Planning work")

    get edit_board_path, headers: { "Accept": "text/html" }

    assert_response :success
    assert_select ".modal-header h2", "Board Settings"
    assert_select "input#board_name_input[value=?]", "Test Board"
    assert_select "textarea#board_description_input", "Planning work"
    assert_select ".modal-section h3", "Board Overview"
  end

  test "can update board settings via modal" do
    patch board_path, params: {
      board: {
        name: "Updated Board",
        description: "Updated description"
      }
    }, headers: { "Accept": "text/vnd.turbo-stream.html" }

    assert_response :ok

    @board.reload
    assert_equal "Updated Board", @board.name
    assert_equal "Updated description", @board.description
    assert_includes response.body, "target=\"board_name\""
    assert_includes response.body, "target=\"board_description\""
  end
end