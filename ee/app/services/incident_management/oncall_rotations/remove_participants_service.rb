# frozen_string_literal: true

module IncidentManagement
  module OncallRotations
    class RemoveParticipantsService
      # @param oncall_rotations [Array<IncidentManagement::OncallRotation>]
      # @param user_to_remove [User]
      # @param async_email [Boolean]
      def initialize(oncall_rotations, user_to_remove, async_email = true)
        @oncall_rotations = oncall_rotations
        @user_to_remove = user_to_remove
        @async_email = async_email
      end

      attr_reader :oncall_rotations, :user_to_remove, :async_email

      def execute
        oncall_rotations.each do |oncall_rotation|
          RemoveParticipantService.new(oncall_rotation, user_to_remove, async_email).execute
        end
      end
    end
  end
end
