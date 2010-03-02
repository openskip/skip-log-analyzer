class Source < ActiveRecord::Base
  has_many :processing_lines
  has_many :parameters_lines
  has_many :current_user_lines
  has_many :rendered_lines
  has_many :completed_lines
  has_many :cache_hit_lines
  has_many :warnings
  has_many :failure_lines
  has_many :query_cached_lines
  has_many :query_executed_lines
end
