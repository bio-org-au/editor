# frozen_string_literal: true

def build_edit_user
  edit_user = User.new
  edit_user.username = "tester"
  edit_user.full_name = "a tester"
  edit_user.groups = [:edit]
  edit_user
end
