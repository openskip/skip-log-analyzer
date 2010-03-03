require 'fastercsv'
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

  # ログインユーザのみを対象とするためにcurrent_user_lineもINNER JOINしている
  named_scope :group_by_url, proc {
    { :group => 'processing_lines.controller, processing_lines.action, processing_lines.format, substr(processing_lines.timestamp, 1, 8)', :joins => [:processing_line, :current_user_line] }
  }

  named_scope :group_by_current_user, proc {
    { :group => 'current_user_lines.user_id, substr(processing_lines.timestamp, 1, 8)', :joins => [:processing_line, :current_user_line] }
  }

  named_scope :group_by_url_and_current_user, proc {
    { :group => 'processing_lines.controller, processing_lines.action, processing_lines.format, current_user_lines.user_id, substr(processing_lines.timestamp, 1, 8)', :joins => [:processing_line, :current_user_line] }
  }

  # ログインユーザのアクセスをアクセス日とアクセスURLでグルーピングしたアクセス数の統計を取得
  def self.frequencies options = {}
    options = {:format => :html}.merge!(options)
    scope = Request.group_by_url
    scope = add_scope(scope, options)
    requests = scope.all(:select => 'requests.*, processing_lines.*, count(processing_lines.action) as hits')
    results = {}
    group_by_date(requests).each do |date, requests_group_by_date|
      results[date] = []
      requests_group_by_date.each do |request|
        pro_line = request.processing_line
        results[date] << {
          :url => "#{pro_line.controller}##{pro_line.action}",
          :hits => request.hits
        }
      end
    end
    results = results.sort_by{ |k,v| k.to_i }
    if options[:format] == 'csv'
      self.generate_csv(results)
    else
      results
    end
  end

  # ログインユーザのアクセスをアクセス日とアクセスURL、及びログインユーザでグルーピングしたアクセス数の統計を取得
  def self.frequencies_per_current_user options = {}
    options = {:format => :html}.merge!(options)
    scope = Request.group_by_url_and_current_user
    scope = add_scope(scope, options)
    requests = scope.all(:select => 'requests.*, processing_lines.*, count(processing_lines.action) as hits')
    results = {}
    group_by_date(requests).each do |date, requests_group_by_date|
      results[date] = {}
      requests_group_by_date.group_by { |request| request.current_user_line.uid }.each do |uid, requests_group_by_current_user|
        results[date][uid] = []
        requests_group_by_current_user.each do |request|
          pro_line = request.processing_line
          results[date][uid] << {
            :url => "#{pro_line.controller}##{pro_line.action}",
            :hits => request.hits
          }
        end
      end
    end
    results = results.sort_by{ |k,v| k.to_i }
    if options[:format] == 'csv'
      self.generate_csv(results)
    else
      results
    end
  end

  # ログインユーザのアクセスをアクセス日とアクセスURL、及び対象ユーザ(params[:uid])でグルーピングしたアクセス数の統計を取得
  def self.frequencies_per_params_uid controller, action, options = {}
    options = {:format => :html}.merge!(options)
    scope = Request.processing_line_controller_is(controller).processing_line_action_is(action)
    scope = add_scope(scope, options)
    requests = scope.all
    results = {}
    group_by_date(requests).each do |date, requests_group_by_date|
      results[date] = {}
      requests_group_by_date.group_by { |request| request.parameters_line.params[:uid] }.each do |uid, requests_group_by_target_user|
        results[date][uid] = {
          :url => "#{controller}##{action}",
          :hits => requests_group_by_target_user.size
        }
      end
    end
    results = results.sort_by{ |k,v| k.to_i }
    if options[:format] == 'csv'
      self.generate_csv(results)
    else
      results
    end
  end

  private

  def self.add_scope scope, options = {}
    scope = scope.processing_line_controller_is(options[:controller]) if options[:controller]
    scope = scope.processing_line_action_is(options[:action]) if options[:action]
    scope = scope.processing_line_timestamp_is(options[:timestamp]) if options[:timestamp]
    scope
  end


  def self.group_by_date requests
    requests.group_by { |request| request.processing_line.timestamp.strftime('%Y%m%d') }
  end

  def self.generate_csv requests_by_date
    FasterCSV.generate do |csv|
      requests_by_date.each do |date, frequencies|
        if frequencies.is_a?(Hash)
          frequencies.each do |k,v|
            if v.is_a?(Hash)
              csv << [date, k, v[:url], v[:hits]]
            elsif v.is_a?(Array)
              v.each do |frequency|
                csv << [date, k, frequency[:url], frequency[:hits]]
              end
            else
              csv << [date, k, v]
            end
          end
        elsif frequencies.is_a?(Array)
          frequencies.each do |frequency|
            csv << [date, frequency[:url], frequency[:hits]]
          end
        else
          csv << [date, frequencies]
        end
      end
    end
  end
end
