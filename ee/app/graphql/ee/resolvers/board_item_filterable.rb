# frozen_string_literal: true

module EE
  module Resolvers
    module BoardItemFilterable
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      override :set_filter_values
      def set_filter_values(filters)
        filter_by_epic(filters)
        filter_by_iteration(filters)
        filter_by_iteration_cadence(filters)
        filter_by_weight(filters)

        super
      end

      private

      def filter_by_epic(filters)
        epic_id = filters.delete(:epic_id)
        epic_wildcard_id = filters.delete(:epic_wildcard_id)

        if epic_id && epic_wildcard_id
          raise ::Gitlab::Graphql::Errors::ArgumentError, 'Incompatible arguments: epicId, epicWildcardId.'
        end

        if epic_id
          filters[:epic_id] = ::GitlabSchema.parse_gid(epic_id, expected_type: ::Epic).model_id
        elsif epic_wildcard_id
          filters[:epic_id] = epic_wildcard_id
        end
      end

      def filter_by_iteration(filters)
        iteration_wildcard_id = filters.delete(:iteration_wildcard_id)
        iterations = filters[:iteration_id]

        if iterations.present? && iteration_wildcard_id
          raise ::Gitlab::Graphql::Errors::ArgumentError, 'Incompatible arguments: iterationId, iterationWildCardId.'
        end

        if iterations.present?
          filters[:iteration_id] = iterations.map do |global_id|
            global_id&.model_id
          end

        elsif iteration_wildcard_id
          filters[:iteration_id] = iteration_wildcard_id
        end
      end

      def filter_by_iteration_cadence(filters)
        return if filters[:iteration_cadence_id].blank?

        filters[:iteration_cadence_id].map!(&:model_id)
      end

      def filter_by_weight(filters)
        weight = filters[:weight]
        weight_wildcard = filters.delete(:weight_wildcard_id)

        if weight && weight_wildcard
          raise ::Gitlab::Graphql::Errors::ArgumentError, 'Incompatible arguments: weight, weightWildcardId.'
        end

        filters[:weight] = weight_wildcard if weight_wildcard
      end
    end
  end
end
