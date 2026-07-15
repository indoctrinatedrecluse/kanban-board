require "test_helper"

class CardIntegrationTest < ActionDispatch::IntegrationTest
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

  # Card modal tests
  test "can fetch card detail modal" do
    get card_path(@card), headers: { "Accept": "text/html" }

    assert_response :success
    assert_select ".modal-header h2", "Edit Card"
    assert_select "input#card_title[value=?]", "Move me"
    assert_select "textarea#card_description"
    assert_select "select#card_priority"
    assert_select "input#card_estimate"
    assert_select "input#card_due_on"
    assert_select "select#card_assignee_id"
    assert_select "input#card_labels"
  end

  test "modal shows current card values" do
    @card.update!(
      description: "Test description",
      priority: "high",
      estimate: 5,
      due_on: Date.today + 1.day,
      labels: "bug, urgent"
    )

    get card_path(@card), headers: { "Accept": "text/html" }

    assert_response :success
    assert_select "input#card_title[value=?]", "Move me"
    assert_select "textarea#card_description", "Test description"
    assert_select "select#card_priority" do
      assert_select "option[selected][value=?]", "high"
    end
    assert_select "input#card_estimate[value=?]", "5"
    assert_select "input#card_labels[value=?]", "bug, urgent"
  end

  test "can update card via modal form" do
    patch card_path(@card), params: {
      card: {
        title: "Updated title",
        description: "Updated description",
        priority: "high",
        estimate: 8,
        due_on: "2024-12-25",
        assignee_id: @user.id,
        labels: "urgent"
      }
    }, headers: { "Accept": "text/vnd.turbo-stream.html" }

    assert_response :ok

    @card.reload
    assert_equal "Updated title", @card.title
    assert_equal "Updated description", @card.description
    assert_equal "high", @card.priority
    assert_equal 8, @card.estimate
    assert_equal "2024-12-25", @card.due_on.to_s
    assert_equal @user.id, @card.assignee_id
    assert_equal "urgent", @card.labels
  end

  test "can clear card description via modal" do
    @card.update!(description: "Some description")

    patch card_path(@card), params: {
      card: { description: "" }
    }, headers: { "Accept": "text/vnd.turbo-stream.html" }

    assert_response :ok

    @card.reload
    assert_empty @card.description
  end

  test "modal form returns turbo_stream on update" do
    patch card_path(@card), params: {
      card: { description: "Updated" }
    }, headers: { "Accept": "text/vnd.turbo-stream.html" }

    assert_response :ok
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
  end

  test "card update via modal maintains column and position" do
    original_column = @card.column
    original_position = @card.position

    patch card_path(@card), params: {
      card: { description: "Updated", priority: "low" }
    }

    @card.reload
    assert_equal original_column, @card.column
    assert_equal original_position, @card.position
  end

  test "can delete a card" do
    assert_difference("Card.count", -1) do
      delete card_path(@card), headers: { "Accept": "text/vnd.turbo-stream.html" }
    end

    assert_response :success
  end
end