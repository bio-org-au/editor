# frozen_string_literal: true

require "test_helper"

class AuthorCreateTest < ActionController::TestCase
  tests AuthorsController

  EDIT_SESSION = { username: "fred", user_full_name: "Fred Jones", groups: ["edit"] }.freeze

  test "creates an author and increments Author count" do
    @request.headers["Accept"] = "application/javascript"
    assert_difference "Author.count", 1 do
      post(:create,
           params: { author: { name: "Integration Test Author", abbrev: "I.T.Auth" } },
           session: EDIT_SESSION)
    end
    assert_response :success
  end

  test "does not create an author when name and abbrev are both blank" do
    @request.headers["Accept"] = "application/javascript"
    assert_no_difference "Author.count" do
      post(:create,
           params: { author: { name: "", abbrev: "" } },
           session: EDIT_SESSION)
    end
    assert_response :unprocessable_content
  end
end
