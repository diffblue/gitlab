# frozen_string_literal: true

module Dora
  module Watchers
    class IssueWatcher
      def self.mount(klass)
        klass.state_machine(:state_id) do
          after_transition any => :closed do |issue|
            Dora::Watchers.process_event(issue, :closed)
          end

          before_transition closed: any do |issue|
            Dora::Watchers.process_event(issue, :reopened)
          end
        end

        klass.after_create do |issue|
          Dora::Watchers.process_event(issue, :created)
        end
      end

      attr_reader :issue, :event

      def initialize(issue, event)
        @issue = issue
        @event = event
      end

      def process
        return unless issue.work_item_type&.incident? && production_env_id

        schedule_metrics_refresh_job
      end

      private

      def schedule_metrics_refresh_job
        date = refresh_date.to_date.iso8601
        env_id = production_env_id

        issue.run_after_commit_or_now do
          ::Dora::DailyMetrics::RefreshWorker.perform_async(env_id, date)
        end
      end

      def refresh_date
        @refresh_date ||= case event
                          when :created
                            issue.created_at
                          when :closed
                            issue.closed_at
                          when :reopened
                            issue.closed_at_was
                          end
      end

      def production_env_id
        @production_env_id ||= issue.project.environments.production.pick(:id)
      end
    end
  end
end
