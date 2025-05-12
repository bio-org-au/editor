module SessionHelper

  def emulate_user_login(session_user, user = nil)
    session[:username] = session_user.username
    session[:user_full_name] = session_user.full_name
    session[:groups] = session_user.groups
    controller.instance_variable_set(:@current_user, session_user)
    allow_any_instance_of(ApplicationController).to receive_messages(
      authenticate: true,
      current_user: session_user,
    )
    if user
      allow(controller).to receive(:current_registered_user).and_return(user)
    end
  end
end

RSpec.configure do |config|
  config.include(SessionHelper)
end
