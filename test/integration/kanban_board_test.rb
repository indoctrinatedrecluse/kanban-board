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
    @card2 = @todo.cards.create!(title: "Original card", priority: "high", position: 2)
  end

  # Basic rendering tests
  test "renders the kanban board" do
    get root_path

    assert_response :success
    assert_select "h1", "Test Board"
    assert_select ".kanban-card h3", "Move me"
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
  end

  # Drag and drop tests
  test "moves a card to another column and position" do
    patch move_card_path(@card), params: { column_id: @doing.id, position: 1 }

    assert_response :success
    @card.reload
    assert_equal @doing, @card.column
    assert_equal 1, @card.position
  end

  test "maintains position ordering when moving cards within same column" do
    card3 = @todo.cards.create!(title: "Third card", priority: "low", position: 3)

    patch move_card_path(@card), params: { column_id: @todo.id, position: 3 }

    @card.reload
    assert_equal 3, @card.position
    assert_equal @todo, @card.column
  end

  test "reorders cards in target column" do
    card_b = @doing.cards.create!(title: "B card", priority: "medium", position: 1)
    card_c = @doing.cards.create!(title: "C card", priority: "low", position: 2)

    patch move_card_path(@card), params: { column_id: @doing.id, position: 2 }

    @card.reload
    card_b.reload
    card_c.reload

    assert_equal 2, @card.position
    assert_equal @doing, @card.column
  end

  # Card reordering within column tests
  test "reorders cards by moving one to a different position in same column" do
    card3 = @todo.cards.create!(title: "Third card", priority: "low", position: 3)
    card4 = @todo.cards.create!(title: "Fourth card", priority: "low", position: 4)

    # Move card4 (position 4) to position 2
    patch move_card_path(card4), params: { column_id: @todo.id, position: 2 }

    card4.reload
    @card.reload
    @card2.reload
    card3.reload

    assert_equal 2, card4.position
    # Other cards should shift down
    assert_equal 1, @card.position
    assert_equal 3, @card2.position
    assert_equal 4, card3.position
  end

  test "reorders cards by moving to top of column" do
    card3 = @todo.cards.create!(title: "Third card", priority: "low", position: 3)

    patch move_card_path(card3), params: { column_id: @todo.id, position: 1 }

    card3.reload
    @card.reload
    @card2.reload

    assert_equal 1, card3.position
    assert_equal 2, @card.position
    assert_equal 3, @card2.position
  end

  test "reorders cards by moving to end of column" do
    card3 = @todo.cards.create!(title: "Third card", priority: "low", position: 3)

    patch move_card_path(@card), params: { column_id: @todo.id, position: 3 }

    @card.reload
    @card2.reload
    card3.reload

    assert_equal 1, @card2.position
    assert_equal 2, card3.position
    assert_equal 3, @card.position
  end

  test "handles reordering same card to same position" do
    initial_position = @card.position

    patch move_card_path(@card), params: { column_id: @todo.id, position: initial_position }

    @card.reload
    assert_equal initial_position, @card.position
  end

  test "reorders across four cards in column" do
    card3 = @todo.cards.create!(title: "Third", priority: "low", position: 3)
    card4 = @todo.cards.create!(title: "Fourth", priority: "low", position: 4)

    # Move card2 from position 2 to position 4
    patch move_card_path(@card2), params: { column_id: @todo.id, position: 4 }

    @card.reload
    @card2.reload
    card3.reload
    card4.reload

    assert_equal 1, @card.position
    assert_equal 2, card3.position
    assert_equal 3, card4.position
    assert_equal 4, @card2.position
  end

  # Card duplication tests
  test "duplicates a card via API" do
    post duplicate_card_path(@card2), params: { target_column_id: @doing.id }

    assert_response :success

    duplicated_card = Card.where(column: @doing).last
    assert_not_nil duplicated_card
    assert_equal "Original card (copy)", duplicated_card.title
    assert_equal @card2.priority, duplicated_card.priority
  end

  test "duplicated card appends to target column" do
    initial_count = @doing.cards.count

    post duplicate_card_path(@card), params: { target_column_id: @doing.id }

    assert_response :success
    @doing.reload
    assert_equal initial_count + 1, @doing.cards.count
  end

  test "duplicate preserves all card metadata" do
    @card.update!(description: "Test description", estimate: 5, labels: "urgent,bug")

    post duplicate_card_path(@card), params: { target_column_id: @doing.id }

    assert_response :success

    duplicated_card = Card.where(column: @doing).last
    assert_equal "Test description", duplicated_card.description
    assert_equal 5, duplicated_card.estimate
    assert_equal "urgent,bug", duplicated_card.labels
  end

  test "duplicate to same column works" do
    initial_count = @todo.cards.count

    post duplicate_card_path(@card), params: { target_column_id: @todo.id }

    assert_response :success
    @todo.reload
    assert_equal initial_count + 1, @todo.cards.count

    duplicated_card = @todo.cards.last
    assert_equal "Move me (copy)", duplicated_card.title
  end

  # Board clear tests
  test "clears all cards from board" do
    @card3 = @todo.cards.create!(title: "Card 3", priority: "low", position: 3)
    @card4 = @doing.cards.create!(title: "Doing card", priority: "medium", position: 1)

    assert_equal 3, @todo.cards.count
    assert_equal 1, @doing.cards.count

    post clear_board_path(@board)

    assert_redirected_to root_path

    @todo.reload
    @doing.reload

    assert_equal 0, @todo.cards.count
    assert_equal 0, @doing.cards.count
  end

  test "clear board keeps columns intact" do
    post clear_board_path(@board)

    @board.reload
    assert_equal 2, @board.columns.count
    assert_equal "To Do", @board.columns.first.name
    assert_equal "Doing", @board.columns.second.name
  end
end
