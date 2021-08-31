# frozen_string_literal: true

module QA
  module Support
    module Formatters
      class TestStatsFormatter < RSpec::Core::Formatters::BaseFormatter
        STATS_DIR = 'tmp/test-stats'

        RSpec::Core::Formatters.register(
          self,
          :start,
          :stop
        )

        # Start test run
        #
        # @param [RSpec::Core::Notifications::StartNotification] _notification
        # @return [void]
        def start(_notification)
          FileUtils.mkdir_p(STATS_DIR)
        end

        # Finish test execution
        #
        # @param [RSpec::Core::Notifications::ExamplesNotification] notification
        # @return [void]
        def stop(notification)
          File.open(File.join(STATS_DIR, "test-stats-#{SecureRandom.uuid}.json"), 'w') do |file|
            specs = notification.examples.map { |example| test_stats(example) }
            file.write(specs.to_json)
          end
        end

        private

        # Get test stats
        #
        # @param [RSpec::Core::Example] example
        # @return [Hash]
        def test_stats(example)
          {
            id: example.id,
            name: example.full_description,
            status: example.execution_result.status,
            reliable: example.metadata.key?(:reliable),
            quarantined: example.metadata.key?(:quarantined),
            run_time: example.execution_result.run_time,
            attempts: example.metadata[:retry_attempts],
            # use allure job name since it is already present and indicates what type of run it is
            # example: staging-full, staging-sanity etc.
            run_type: ENV['ALLURE_JOB_NAME']
          }
        end
      end
    end
  end
end
