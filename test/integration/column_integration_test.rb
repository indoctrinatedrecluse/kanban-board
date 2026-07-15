require "test_helper"

class ColumnIntegrationTest < ActionDispatch::IntegrationTest
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

  # Column modal tests
  test "can fetch column edit modal" do
    get column_path(@todo), headers: { "Accept": "text/html" }

    assert_response :success
    assert_select ".modal-header h2", "Edit Column"
    assert_select "input#column_name[value=?]", "To Do"
    assert_select "input#column_wip_limit"
    assert_select ".modal-section"
  end

  test "column modal shows card count" do
    get column_path(@todo), headers: { "Accept": "text/html" }

    assert_response :success
    assert_select ".stat-item", /Cards in column.*2/
  end

  test "column modal shows total points" do
    @card.update!(estimate: 3)
    @card2.update!(estimate: 5)

    get column_path(@todo), headers: { "Accept": "text/html" }

    assert_response :success
    assert_select ".stat-item", /Total points.*8/
  end

  test "column modal shows assignee list" do
    @card2.update!(assignee: @user)

    get column_path(@todo), headers: { "Accept": "text/html" }

    assert_response :success
    assert_select ".modal-section h3", "Assignees"
    assert_select ".stat-item", /Avery Chen.*2 cards/
  end

  test "column modal shows WIP usage when limit is set" do
    @todo.update(wip_limit: 5)

    get column_path(@todo), headers: { "Accept": "text/html" }

    assert_response :success
    assert_select ".stat-item", /WIP Usage.*2\/5/
  end

  test "column modal shows WIP warning when over limit" do
    @todo.update(wip_limit: 1)

    get column_path(@todo), headers: { "Accept": "text/html" }

    assert_response :success
    assert_select ".warning-badge", /Over limit/
  end

  test "can update column name via modal" do
    patch column_path(@todo), params: {
      column: { name: "Updated Column Name" }
    }, headers: { "Accept": "text/vnd.turbo-stream.html" }

    assert_response :ok

    @todo.reload
    assert_equal "Updated Column Name", @todo.name
  end

  test "can update column WIP limit via modal" do
    patch column_path(@todo), params: {
      column: { wip_limit: 10 }
    }, headers: { "Accept": "text/vnd.turbo-stream.html" }

    assert_response :ok

    @todo.reload
    assert_equal 10, @todo.wip_limit
  end

  test "can clear column WIP limit via modal" do
    @todo.update(wip_limit: 5)

    patch column_path(@todo), params: {
      column: { wip_limit: "" }
    }, headers: { "Accept": "text/vnd.turbo-stream.html" }

    assert_response :ok

    @todo.reload
    assert_nil @todo.wip_limit
  end

  test "column update returns turbo_stream" do
    patch column_path(@todo), params: {
      column: { name: "New Name" }
    }, headers: { "Accept": "text/vnd.turbo-stream.html" }

    assert_response :ok
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_includes response.body, "target=\"column_#{@todo.id}\""
  end

  test "can update column and maintain cards" do
    initial_card_count = @todo.cards.count

    patch column_path(@todo), params: {
      column: { name: "Renamed Column", wip_limit: 8 }
    }, headers: { "Accept": "text/vnd.turbo-stream.html" }

    @todo.reload
    assert_equal "Renamed Column", @todo.name
    assert_equal 8, @todo.wip_limit
    assert_equal initial_card_count, @todo.cards.count
  end
end