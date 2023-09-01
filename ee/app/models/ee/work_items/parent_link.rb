# frozen_string_literal: true

module EE
  module WorkItems
    module ParentLink
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      override :validate_hierarchy_restrictions
      def validate_hierarchy_restrictions
        super

        validate_legacy_hierarchy
      end

      private

      def validate_legacy_hierarchy
        return unless work_item_parent&.work_item_type&.base_type == 'epic' && work_item&.has_epic?

        errors.add :work_item, _('already assigned to an epic')
      end
    end
  end
end
