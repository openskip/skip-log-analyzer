class QueryCachedLine < ActiveRecord::Base
  belongs_to :source
  belongs_to :request
end
