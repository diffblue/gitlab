# frozen_string_literal: true

module EE
  module WorkItems
    module ImportCsvService
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      override :available_work_item_types
      def available_work_item_types
        super.merge({
          requirement: {
            allowed: can_create_requirements?,
            type: ::WorkItems::Type.default_by_type(:requirement)
          }
        }).with_indifferent_access
      end

      def can_create_requirements?
        Ability.allowed?(user, :create_requirement, project)
      end
    end
  end
end
