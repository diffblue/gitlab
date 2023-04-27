# frozen_string_literal: true

module EE
  module Notes
    module QuickActionsService
      extend ActiveSupport::Concern
      include ::Gitlab::Utils::StrongMemoize

      prepended do
        EE_SUPPORTED_NOTEABLES = %w[Epic].freeze
        EE::Notes::QuickActionsService.private_constant :EE_SUPPORTED_NOTEABLES
      end

      class_methods do
        extend ::Gitlab::Utils::Override

        override :supported_noteables
        def supported_noteables
          super + EE_SUPPORTED_NOTEABLES
        end
      end

      def noteable_update_service(note, update_params)
        return super unless note.for_epic?

        Epics::UpdateService.new(group: note.resource_parent, current_user: current_user, params: update_params)
      end
    end
  end
end
