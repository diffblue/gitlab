# frozen_string_literal: true

module EE
  module Ci
    module Deployable
      extend ActiveSupport::Concern

      prepended do
        state_machine :status do
          before_transition on: :enqueue do |job|
            !job.waiting_for_deployment_approval? # If false is returned, it stops the transition
          end
        end
      end

      def waiting_for_deployment_approval?
        manual? && deployment_job? && deployment&.waiting_for_approval?
      end
    end
  end
end
