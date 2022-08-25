# frozen_string_literal: true

module EE
  module GraphqlTriggers
    extend ActiveSupport::Concern
    prepended do
      def self.issuable_weight_updated(issuable)
        ::GitlabSchema.subscriptions.trigger('issuableWeightUpdated', { issuable_id: issuable.to_gid }, issuable)
      end
    end
  end
end
