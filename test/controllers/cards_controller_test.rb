require "test_helper"

class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Board.destroy_all
    User.destroy_all

    @user = User.create!(name: "Test User", email: "test@example.test")
    @board = Board.create!(name: "Test Board")
    @todo = @board.columns.create!(name: "To Do", position: 1)
    @doing = @board.columns.create!(name: "Doing", position: 2)
    @card = @todo.cards.create!(
      title: "Test Card",
      priority: "medium",
      description: "Original description",
      estimate: 8,
      labels: "bug,critical",
      due_on: Date.tomorrow,
      assignee: @user,
      position: 1
    )
  end

  test "show renders the card edit modal" do
    get card_path(@card), headers: { "Accept": "text/html" }

    assert_response :success
    assert_select ".modal-header h2", "Edit Card"
    assert_select "input[name='card[title]'][value=?]", "Test Card"
    assert_select "select[name='card[assignee_id]'] option[selected][value=?]", @user.id.to_s
  end

  test "update changes editable card fields and returns turbo stream" do
    patch card_path(@card), params: {
      card: {
        title: "Updated Card",
        description: "Updated description",
        priority: "high",
        estimate: 13,
        labels: "feature",
        due_on: "2026-08-01",
        assignee_id: ""
      }
    }, headers: { "Accept": "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type

    @card.reload
    assert_equal "Updated Card", @card.title
    assert_equal "Updated description", @card.description
    assert_equal "high", @card.priority
    assert_equal 13, @card.estimate
    assert_equal "feature", @card.labels
    assert_equal "2026-08-01", @card.due_on.to_s
    assert_nil @card.assignee
  end

  test "move changes column and position" do
    patch move_card_path(@card), params: { column_id: @doing.id, position: 1 }

    assert_response :ok
    @card.reload
    assert_equal @doing, @card.column
    assert_equal 1, @card.position
  end

  test "move reorders cards in the same column" do
    second = @todo.cards.create!(title: "Second", priority: "low", position: 2)
    third = @todo.cards.create!(title: "Third", priority: "low", position: 3)

    patch move_card_path(third), params: { column_id: @todo.id, position: 1 }

    [@card, second, third].each(&:reload)
    assert_equal [third, @card, second], @todo.reload.cards.to_a
  end

  test "duplicate creates a copied card with metadata" do
    assert_difference "Card.count", 1 do
      post duplicate_card_path(@card), params: { target_column_id: @doing.id }
    end

    assert_response :success
    duplicated = @doing.cards.reload.last
    assert_equal "Test Card (copy)", duplicated.title
    assert_equal "Original description", duplicated.description
    assert_equal "medium", duplicated.priority
    assert_equal 8, duplicated.estimate
    assert_equal "bug,critical", duplicated.labels
    assert_equal Date.tomorrow, duplicated.due_on
    assert_equal @user, duplicated.assignee
    assert_match /kanban-card/, response.body
  end
end
