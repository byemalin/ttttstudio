class ApplicationController < ActionController::Base
  before_action :set_navbar_users

  private

  def set_navbar_users
    # @ezra_user = User.find_by(name: "Ezra")
    # @jun_user = User.find_by(name: "Jun")
    @malin_user = User.find_by(email: "malin@byemalin.com")
    @rocco_user = User.find_by(email: "rocco.montagnoli@gmail.com")
  end
end
