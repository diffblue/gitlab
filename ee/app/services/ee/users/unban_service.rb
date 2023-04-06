# frozen_string_literal: true

module EE
  module Users
    module UnbanService
      extend ::Gitlab::Utils::Override
      include ManagementBaseService

      private

      def event_name
        'unban_user'
      end

      def event_message
        'Unbanned user'
      end
    end
  end
end
