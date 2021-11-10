# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class GroupDataLoaderWorker
      include ApplicationWorker

      data_consistency :always
      feature_category :value_stream_management

      idempotent!

      MODEL_KLASSES = %w[Issue MergeRequest].freeze

      def perform(group_id, model_klass = MODEL_KLASSES.first, cursor = {}, updated_at_before = Time.current)
        group = Group.find_by_id(group_id)
        return unless group

        model = model_klass.safe_constantize
        return unless model

        next_model = MODEL_KLASSES[MODEL_KLASSES.index(model_klass) + 1]

        response = Analytics::CycleAnalytics::DataLoaderService.new(
          group: group,
          model: model,
          cursor: cursor,
          updated_at_before: updated_at_before
        ).execute

        if response.error?
          log_extra_metadata_on_done(:error_reason, response[:reason])
        elsif response.payload[:reason] == :limit_reached
          self.class.perform_in(
            2.minutes,
            group_id,
            model.to_s,
            response.payload[:cursor],
            updated_at_before
          )
        elsif response.payload[:reason] == :model_processed && next_model
          self.class.perform_in(
            2.minutes,
            group_id,
            next_model,
            {},
            updated_at_before
          )
        end

        true
      end
    end
  end
end
