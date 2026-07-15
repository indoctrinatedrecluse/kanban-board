require "test_helper"

class ColumnsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Board.destroy_all
    User.destroy_all

    @user = User.create!(name: "Test User", email: "test@example.test")
    @board = Board.create!(name: "Test Board")
    @column = @board.columns.create!(name: "To Do", position: 1, wip_limit: 2)
    @column.cards.create!(title: "Card 1", priority: "medium", estimate: 3, assignee: @user, position: 1)
    @column.cards.create!(title: "Card 2", priority: "high", estimate: 5, position: 2)
  end

  test "show renders the column edit modal" do
    get column_path(@column), headers: { "Accept": "text/html" }

    assert_response :success
    assert_select ".modal-header h2", "Edit Column"
    assert_select "input[name='column[name]'][value=?]", "To Do"
    assert_select "input[name='column[wip_limit]'][value=?]", "2"
    assert_select ".stat-item", /Cards in column:.*2/
    assert_select ".stat-item", /Total points:.*8/
    assert_select ".modal-section h3", "Assignees"
    assert_select ".stat-item", /Test User.*1 card/
  end

  test "update changes column settings and returns turbo stream" do
    patch column_path(@column), params: {
      column: {
        name: "Ready",
        wip_limit: ""
      }
    }, headers: { "Accept": "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_includes response.body, "target=\"column_#{@column.id}\""

    @column.reload
    assert_equal "Ready", @column.name
    assert_nil @column.wip_limit
  end
end
