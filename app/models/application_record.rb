class ApplicationRecord < ActiveRecord::Base
  include Discard::Model

  primary_abstract_class
end
