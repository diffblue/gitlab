# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class GroupLevel
      attr_reader :options, :group

      def initialize(group:, options:)
        @group = group
        @options = options.merge(group: group)
      end

      def summary
        @summary ||=
          Gitlab::Analytics::CycleAnalytics::Summary::Group::StageSummary
          .new(group, options: options)
          .data
      end

      def time_summary
        @time_summary ||= begin
          stage = ::Analytics::CycleAnalytics::Stage.new(namespace: group)

          Gitlab::Analytics::CycleAnalytics::Summary::StageTimeSummary
            .new(stage, options: options)
            .data
        end
      end
    end
  end
end
