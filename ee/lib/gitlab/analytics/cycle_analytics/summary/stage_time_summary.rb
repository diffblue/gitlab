# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        class StageTimeSummary
          attr_reader :stage, :current_user, :options

          def initialize(stage, options:)
            @stage = stage
            @current_user = options[:current_user]
            @options = options
          end

          def data
            [lead_time, cycle_time, time_to_merge].tap do |array|
              array << serialize(lead_time_for_changes, with_unit: true) if lead_time_for_changes.value.present?
              array << serialize(time_to_restore_service, with_unit: true) if time_to_restore_service.value.present?
              array << serialize(change_failure_rate, with_unit: true) if change_failure_rate.value.present?
            end
          end

          private

          def lead_time
            serialize(
              Summary::LeadTime.new(
                stage: stage, current_user: current_user, options: options
              ),
              with_unit: true
            )
          end

          def cycle_time
            serialize(
              Summary::CycleTime.new(
                stage: stage, current_user: current_user, options: options
              ),
              with_unit: true
            )
          end

          def time_to_merge
            serialize(
              Summary::TimeToMerge.new(
                stage: stage, current_user: current_user, options: options
              ),
              with_unit: true
            )
          end

          def lead_time_for_changes
            @lead_time_for_changes ||= Summary::LeadTimeForChanges.new(
              stage: stage,
              current_user: current_user,
              options: options
            )
          end

          def time_to_restore_service
            @time_to_restore_service ||= Summary::TimeToRestoreService.new(
              stage: stage,
              current_user: current_user,
              options: options
            )
          end

          def change_failure_rate
            @change_failure_rate ||= Summary::ChangeFailureRate.new(
              stage: stage,
              current_user: current_user,
              options: options
            )
          end

          def serialize(summary_object, with_unit: false)
            AnalyticsSummarySerializer.new.represent(
              summary_object, with_unit: with_unit)
          end
        end
      end
    end
  end
end
