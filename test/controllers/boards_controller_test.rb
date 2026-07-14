require "test_helper"

class BoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Board.destroy_all

    @board = Board.create!(name: "Test Board", description: "Test Description")
    @column1 = @board.columns.create!(name: "To Do", position: 1)
    @column2 = @board.columns.create!(name: "Doing", position: 2)
    @card1 = @column1.cards.create!(title: "Card 1", priority: "medium", position: 1)
    @card2 = @column2.cards.create!(title: "Card 2", priority: "high", position: 1)
  end

  test "show renders board" do
    get root_path

    assert_response :success
    assert_select "h1", "Test Board"
  end

  test "show displays board stats" do
    get root_path

    assert_response :success
    assert_select ".board-stats", /2 cards/
  end

  test "show displays menu" do
    get root_path

    assert_response :success
    assert_select ".board-menu"
  end

  test "clear removes all cards" do
    assert_equal 1, @column1.cards.count
    assert_equal 1, @column2.cards.count

    post clear_board_path(@board)

    @column1.reload
    @column2.reload

    assert_equal 0, @column1.cards.count
    assert_equal 0, @column2.cards.count
  end

  test "clear keeps columns intact" do
    assert_equal 2, @board.columns.count

    post clear_board_path(@board)

    @board.reload
    assert_equal 2, @board.columns.count
    assert_equal "To Do", @board.columns.first.name
    assert_equal "Doing", @board.columns.second.name
  end

  test "clear redirects to root" do
    post clear_board_path(@board)

    assert_redirected_to root_path
  end

  test "clear shows notice" do
    post clear_board_path(@board)

    assert_equal "Board cleared successfully", flash[:notice]
  end

  test "clear with empty board works" do
    @column1.cards.destroy_all
    @column2.cards.destroy_all

    post clear_board_path(@board)

    assert_redirected_to root_path
  end
end
