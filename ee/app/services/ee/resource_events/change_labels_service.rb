# frozen_string_literal: true

module EE
  module ResourceEvents
    module ChangeLabelsService
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(added_labels: [], removed_labels: [])
        super

        return unless resource.is_a?(Epic)

        ::Gitlab::UsageDataCounters::EpicActivityUniqueCounter.track_epic_labels_changed_action(
          author: user,
          namespace: resource.group
        )
      end

      override :resource_column
      def resource_column(resource)
        resource.is_a?(Epic) ? :epic_id : super
      end
    end
  end
end
