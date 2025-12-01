class ApplicationController < ActionController::Base
  include Pagy::Backend
  Pagy::DEFAULT[:items] = 20
  allow_browser versions: :modern
end
