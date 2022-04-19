# frozen_string_literal: true

module IncidentManagement
  module OncallRotations
    class RemoveParticipantService < OncallRotations::BaseService
      include IncidentManagement::OncallRotations::SharedRotationLogic
      # @param oncall_rotations [IncidentManagement::OncallRotation]
      # @param user_to_remove [User]
      # @param async_email [Boolean]
      def initialize(oncall_rotation, user_to_remove, async_email = true)
        super(project: oncall_rotation.project)

        @oncall_rotation = oncall_rotation
        @user_to_remove = user_to_remove
        @async_email = async_email
      end

      def execute
        ensure_rotation_is_up_to_date

        deleted = remove_user_from_rotation

        if deleted
          save_current_shift!
          send_notification
        end
      end

      private

      attr_reader :oncall_rotation, :user_to_remove, :async_email

      def remove_user_from_rotation
        participant = oncall_rotation.participants.for_user(user_to_remove).first

        return unless participant

        participant.update!(is_removed: true)

        oncall_rotation.touch
      end

      def send_notification
        NotificationService.new.oncall_user_removed(oncall_rotation, user_to_remove, async_email)
      end
    end
  end
end
