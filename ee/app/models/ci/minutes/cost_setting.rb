# frozen_string_literal: true

# Stores a ci minute cost settings per runner including
# Cost Factors which are applied to build minutes based on project attributes
#
module Ci
  module Minutes
    class CostSetting < ::Ci::ApplicationRecord
      include Ci::NamespacedModelName

      belongs_to :runner, class_name: 'Ci::Runner', inverse_of: :cost_settings

      validates :standard_factor, presence: true, numericality: true
      validates :os_contribution_factor, presence: true, numericality: true
      validates :os_plan_factor, presence: true, numericality: true

      validate :shared_runner_presence

      private

      def shared_runner_presence
        errors.add(:runner, "must be shared") unless runner&.instance_type?
      end
    end
  end
end
