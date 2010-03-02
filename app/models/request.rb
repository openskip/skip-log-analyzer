class Request < ActiveRecord::Base
  has_one :processing_line
  has_one :parameters_line
  has_one :current_user_line
  has_one :rendered_line
  has_one :completed_line
  has_one :cache_hit_line
  has_one :failure_line
  has_one :query_cached_line
  has_one :query_executed_line
end
