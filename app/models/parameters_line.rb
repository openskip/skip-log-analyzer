class ParametersLine < ActiveRecord::Base
  belongs_to :source
  belongs_to :request

  serialize :params
end
