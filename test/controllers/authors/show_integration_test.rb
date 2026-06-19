# frozen_string_literal: true

require "test_helper"

class AuthorShowTest < ActionController::TestCase
  tests AuthorsController

  setup do
    @author = authors(:bentham)
  end

  test "show returns a successful response" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @author.id, tab: "tab_show_1" },
        session: { username: "fred", user_full_name: "Fred Jones", groups: ["read"] })
    assert_response :success
  end

  test "show response includes the author name" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @author.id, tab: "tab_show_1" },
        session: { username: "fred", user_full_name: "Fred Jones", groups: ["read"] })
    assert_match @author.name.strip, response.body
  end
end
