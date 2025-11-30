class DashboardController < ApplicationController
  def index
    @presenter = DashboardPresenter.new
  end
end
