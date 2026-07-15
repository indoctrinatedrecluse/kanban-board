require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "can be assigned to cards" do
    user = users(:one)

    assert_respond_to user, :assigned_cards
  end
end
