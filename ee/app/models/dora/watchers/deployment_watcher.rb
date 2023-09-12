# frozen_string_literal: true

module Dora
  module Watchers
    class DeploymentWatcher
      def self.mount(klass)
        klass.state_machine :status do
          after_transition any => :success do |deployment|
            Dora::Watchers.process_event(deployment, :successful)
          end
        end
      end

      attr_reader :deployment, :event

      def initialize(deployment, event)
        @deployment = deployment
        @event = event
      end

      def process
        env_id = deployment.environment_id
        refresh_date = deployment.finished_at.to_date.iso8601

        deployment.run_after_commit_or_now do
          # Schedule to refresh the DORA daily metrics.
          # It has 5 minutes delay due to waiting for the other async processes
          # (e.g. `LinkMergeRequestWorker`) to be finished before collecting metrics.
          ::Dora::DailyMetrics::RefreshWorker.perform_in(5.minutes, env_id, refresh_date)
        end
      end
    end
  end
end
