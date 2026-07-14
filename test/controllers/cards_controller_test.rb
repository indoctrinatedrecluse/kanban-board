require "test_helper"

class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Board.destroy_all
    User.destroy_all

    @user = User.create!(name: "Test User", email: "test@example.test")
    @board = Board.create!(name: "Test Board")
    @column1 = @board.columns.create!(name: "Column 1", position: 1)
    @column2 = @board.columns.create!(name: "Column 2", position: 2)
    @card = @column1.cards.create!(title: "Test Card", priority: "medium", position: 1)
  end

  # Move action tests
  test "move card returns 200 OK" do
    patch move_card_path(@card), params: { column_id: @column2.id, position: 1 }
    assert_response :ok
  end

  test "move card updates column" do
    patch move_card_path(@card), params: { column_id: @column2.id, position: 1 }

    @card.reload
    assert_equal @column2, @card.column
  end

  test "move card updates position" do
    patch move_card_path(@card), params: { column_id: @column2.id, position: 3 }

    @card.reload
    assert_equal 3, @card.position
  end

  # Duplicate action tests
  test "duplicate card returns success" do
    post duplicate_card_path(@card), params: { target_column_id: @column2.id }
    assert_response :success
  end

  test "duplicate card creates new card" do
    assert_difference "Card.count" do
      post duplicate_card_path(@card), params: { target_column_id: @column2.id }
    end
  end

  test "duplicate card appends (copy) to title" do
    post duplicate_card_path(@card), params: { target_column_id: @column2.id }

    duplicated = Card.where(column: @column2).last
    assert_equal "Test Card (copy)", duplicated.title
  end

  test "duplicate card preserves priority" do
    post duplicate_card_path(@card), params: { target_column_id: @column2.id }

    duplicated = Card.where(column: @column2).last
    assert_equal "medium", duplicated.priority
  end

  test "duplicate card preserves description" do
    @card.update!(description: "Original description")

    post duplicate_card_path(@card), params: { target_column_id: @column2.id }

    duplicated = Card.where(column: @column2).last
    assert_equal "Original description", duplicated.description
  end

  test "duplicate card preserves estimate" do
    @card.update!(estimate: 8)

    post duplicate_card_path(@card), params: { target_column_id: @column2.id }

    duplicated = Card.where(column: @column2).last
    assert_equal 8, duplicated.estimate
  end

  test "duplicate card preserves labels" do
    @card.update!(labels: "bug,critical")

    post duplicate_card_path(@card), params: { target_column_id: @column2.id }

    duplicated = Card.where(column: @column2).last
    assert_equal "bug,critical", duplicated.labels
  end

  test "duplicate card preserves due_on" do
    due_date = Date.tomorrow
    @card.update!(due_on: due_date)

    post duplicate_card_path(@card), params: { target_column_id: @column2.id }

    duplicated = Card.where(column: @column2).last
    assert_equal due_date, duplicated.due_on
  end

  test "duplicate does preserve assignee via dup method" do
    @card.update!(assignee: @user)

    post duplicate_card_path(@card), params: { target_column_id: @column2.id }

    duplicated = Card.where(column: @column2).last
    # Note: Ruby's dup method copies the association, so assignee_id is preserved
    assert_equal @user, duplicated.assignee
  end

  test "duplicate to same column works" do
    assert_difference "Card.count" do
      post duplicate_card_path(@card), params: { target_column_id: @column1.id }
    end

    duplicated = Card.where(column: @column1).last
    assert_equal "Test Card (copy)", duplicated.title
  end

  test "duplicate returns partial HTML" do
    post duplicate_card_path(@card), params: { target_column_id: @column2.id }

    assert_response :success
    assert_match /kanban-card/, response.body
    assert_match /Test Card \(copy\)/, response.body
  end

  # Reordering within column tests
  test "reorders card within same column" do
    card2 = @column1.cards.create!(title: "Card 2", priority: "low", position: 2)
    card3 = @column1.cards.create!(title: "Card 3", priority: "low", position: 3)

    # Move card3 to position 1
    patch move_card_path(card3), params: { column_id: @column1.id, position: 1 }

    card3.reload
    @card.reload
    card2.reload

    assert_equal 1, card3.position
    assert_equal 2, @card.position
    assert_equal 3, card2.position
  end

  test "handles same position move (no change)" do
    card2 = @column1.cards.create!(title: "Card 2", priority: "low", position: 2)

    # Try to move card to its current position
    patch move_card_path(@card), params: { column_id: @column1.id, position: 1 }

    @card.reload
    assert_equal 1, @card.position
  end

  test "reorders multiple cards when middle card moves" do
    card2 = @column1.cards.create!(title: "Card 2", priority: "low", position: 2)
    card3 = @column1.cards.create!(title: "Card 3", priority: "low", position: 3)
    card4 = @column1.cards.create!(title: "Card 4", priority: "low", position: 4)

    # Move card2 to position 4
    patch move_card_path(card2), params: { column_id: @column1.id, position: 4 }

    @card.reload
    card2.reload
    card3.reload
    card4.reload

    assert_equal 1, @card.position
    assert_equal 2, card3.position
    assert_equal 3, card4.position
    assert_equal 4, card2.position
  end
end
