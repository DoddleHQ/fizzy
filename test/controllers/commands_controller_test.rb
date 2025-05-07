require "test_helper"

class CommandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "command that results in a redirect" do
    assert_difference -> { users(:kevin).commands.count }, +1 do
      post commands_path, params: { command: "#{cards(:logo).id}" }
    end

    assert_redirected_to cards(:logo)
  end

  test "command that triggers a redirect back" do
    assert_difference -> { users(:kevin).commands.count }, +1 do
      post commands_path, params: { command: "/assign @kevin", confirmed: "confirmed" }, headers: { "HTTP_REFERER" => cards_path }
    end

    assert_redirected_to cards_path
  end

  test "commands requiring confirmation return a 409 conflict response" do
    assert_no_difference -> { users(:kevin).commands.count } do
      post commands_path, params: { command: "/assign @kevin" }, headers: { "HTTP_REFERER" => cards_path }
    end

    assert_response :conflict
  end

  test "get a 422 on errors" do
    post commands_path, params: { command: "/assign @some_missing_user" }, headers: { "HTTP_REFERER" => cards_path }
    assert_response :unprocessable_entity
  end
end
