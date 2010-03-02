class CurrentUserLine < ActiveRecord::Base
  belongs_to :source
  belongs_to :request
end
