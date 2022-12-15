# frozen_string_literal: true

module Gitlab
  module Insights
    module Reducers
      class CountPerLabelReducer < BaseReducer
        InvalidLabelsError = Class.new(BaseReducerError)

        def initialize(issuables, labels:)
          super(issuables)
          @labels = Array(labels)

          validate!
        end

        # Returns a hash { label => issuables_count }, e.g.
        #   {
        #     'Manage' => 2,
        #     'Plan' => 3,
        #     'undefined' => 1
        #   }
        def reduce
          count_per_label
        end

        private

        attr_reader :labels

        def validate!
          unless labels.any?
            raise InvalidLabelsError, "Invalid value for `labels`: `#{labels}`. It must be a non-empty array!"
          end
        end

        def count_per_label
          issuables.each_with_object(initial_labels_count_hash) do |issuable, hash|
            issuable_labels = issuable.labels.map(&:title)
            detected_label = labels.detect { |label| issuable_labels.include?(label) }
            hash[detected_label || Gitlab::Insights::UNCATEGORIZED] += 1
          end
        end

        def initial_labels_count_hash
          (labels + [Gitlab::Insights::UNCATEGORIZED]).index_with do |label|
            0
          end
        end
      end
    end
  end
end
