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

  named_scope :group_by_url, proc {
    { :group => 'processing_lines.controller, processing_lines.action, processing_lines.format, substr(processing_lines.timestamp, 1, 8)', :joins => :processing_line }
  }

  named_scope :group_by_url_and_current_user, proc {
    { :group => 'processing_lines.controller, processing_lines.action, processing_lines.format, current_user_lines.user_id, substr(processing_lines.timestamp, 1, 8)', :joins => [:processing_line, :current_user_line] }
  }

  named_scope :group_by_current_user, proc {
    { :group => 'current_user_lines.user_id, substr(processing_lines.timestamp, 1, 8)', :joins => [:processing_line, :current_user_line] }
  }

  def self.frequencies_per_uid controller, action, options = {}
    options = {:format => :html}.merge!(options)
    requests = Request.processing_line_controller_is(controller).processing_line_action_is(action)
    results = {}
    requests.group_by { |request| request.processing_line.timestamp.strftime('%Y%m%d') }.each do |date, requests_group_by_date|
      results[date] = {}
      pro_line = requests_group_by_date.first..processing_line
      requests_group_by_date.group_by { |request| request.parameters_line.params[:uid] }.each do |uid, requests_group_by_target_user|
        results[date][uid] = {
          :url => "#{pro_line.controller}##{pro_line.action}",
          :hits => requests_group_by_target_user.size
        }
      end
    end
    results
  end

  def self.frequencies options = {}
    options = {:format => :html}.merge!(options)
    requests = Request.group_by_url.all(:select => 'requests.*, processing_lines.*, count(processing_lines.action) as hits')
    results = {}
    requests.group_by { |request| request.processing_line.timestamp.strftime('%Y%m%d') }.each do |date, requests_group_by_date|
      results[date] = []
      requests_group_by_date.each do |request|
        pro_line = request.processing_line
        results[date] << {
          :url => "#{pro_line.controller}##{pro_line.action}",
          :hits => requests_group_by_date.size
        }
      end
    end
    results
  end

  def self.frequencies_per_current_user options = {}
    requests = Request.group_by_url_and_current_user.all(:select => 'requests.*, processing_lines.*, count(processing_lines.action) as hit')
    results = {}
    requests.group_by { |request| request.processing_line.timestamp.strftime('%Y%m%d') }.each do |date, requests_group_by_date|
      results[date] = {}
      requests_group_by_date.group_by { |request| request.current_user_line.uid }.each do |uid, requests_group_by_current_user|
        results[date][uid] = []
        requests_group_by_current_user.each do |request|
          pro_line = request.processing_line
          results[date][uid] << {
            :url => "#{pro_line.controller}##{pro_line.action}",
            :hits => requests_group_by_current_user.size
          }
        end
      end
    end
    results
  end
end
