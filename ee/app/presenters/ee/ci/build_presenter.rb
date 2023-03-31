# frozen_string_literal: true

module EE
  module Ci
    module BuildPresenter
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::DelegatorOverride

      delegator_override :retryable?
      def retryable?
        # The merge_train_pipeline? is more expensive and less frequent condition
        super && !merge_train_pipeline?
      end
    end
  end
end
