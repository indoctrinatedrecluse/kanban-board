require "test_helper"

class AssigneeIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    Board.destroy_all
    User.destroy_all

    @user = User.create!(name: "Avery Chen", email: "avery-test@example.test")
    @board = Board.create!(name: "Test Board")
  end

  test "can open assignees modal" do
    get root_path
    assert_response :success

    get assignees_board_path, headers: { "Accept": "text/html" }
    assert_response :success
    assert_select ".modal-header h2", "Manage Assignees"
  end

  test "can add an assignee" do
    assert_difference("User.count") do
      post add_assignee_board_path, params: { name: "New User" }, headers: { "Accept": "text/vnd.turbo-stream.html" }
    end
    assert_response :ok
    assert_includes response.body, "target=\"assignees_modal\""
    assert_includes response.body, "target=\"board_stats\""
  end

  test "can remove an assignee" do
    assert_difference("User.count", -1) do
      delete remove_assignee_board_path(id: @user.id), headers: { "Accept": "text/vnd.turbo-stream.html" }
    end
    assert_response :ok
    assert_includes response.body, "target=\"assignees_modal\""
    assert_includes response.body, "target=\"board_stats\""
  end
end
