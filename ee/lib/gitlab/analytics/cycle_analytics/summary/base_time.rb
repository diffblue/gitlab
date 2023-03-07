# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        class BaseTime
          include Gitlab::CycleAnalytics::Summary::Defaults

          attr_reader :stage

          def initialize(stage:, current_user:, options:)
            @stage = stage
            @current_user = current_user
            @options = options

            assign_stage_metadata
          end

          def raw_value
            data_collector.median.days&.round(1)
          end

          def value
            @value ||= Gitlab::CycleAnalytics::Summary::Value::PrettyNumeric.new(raw_value)
          end

          def unit
            n_('day', 'days', value)
          end

          def self.start_event_identifier
            raise NotImplementedError, "Expected #{self.name} to implement start_event_identifier"
          end

          def self.end_event_identifier
            raise NotImplementedError, "Expected #{self.name} to implement end_event_identifier"
          end

          private

          # rubocop: disable CodeReuse/ActiveRecord
          def assign_stage_metadata
            @stage.start_event_identifier = self.class.start_event_identifier
            @stage.end_event_identifier = self.class.end_event_identifier

            if @options[:use_aggregated_data_collector]
              # Gitlab::Analytics::CycleAnalytics::DistinctStageLoader ensures that we have StageEventHash record
              # for the subclasses (LeadTime, CycleTime) however, it is an asynchronous process. There can be a short period
              # of time where the query below returns nil. To handle this, we're pre-setting "None" value.
              @stage.stage_event_hash_id = ::Analytics::CycleAnalytics::StageEventHash.find_by(hash_sha256: @stage.events_hash_code)&.id
              @value = Gitlab::CycleAnalytics::Summary::Value::None.new if @stage.stage_event_hash_id.blank?
            end
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def data_collector
            Gitlab::Analytics::CycleAnalytics::DataCollector.new(
              stage: @stage,
              params: {
                from: @options[:from],
                to: @options[:to] || DateTime.now,
                project_ids: @options[:projects],
                end_event_filter: @options[:end_event_filter],
                current_user: @current_user,
                use_aggregated_data_collector: @options[:use_aggregated_data_collector]
              }.merge(@options.slice(*::Gitlab::Analytics::CycleAnalytics::RequestParams::FINDER_PARAM_NAMES))
            )
          end
        end
      end
    end
  end
end
