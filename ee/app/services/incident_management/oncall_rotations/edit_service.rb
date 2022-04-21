# frozen_string_literal: true

module IncidentManagement
  module OncallRotations
    class EditService < OncallRotations::BaseService
      include IncidentManagement::OncallRotations::SharedRotationLogic
      # @param rotation [IncidentManagement::OncallRotation]
      # @param user [User]
      # @param edit_params [Hash<Symbol,Any>]
      # @param edit_params - name [String] The name of the on-call rotation.
      # @param edit_params - length [Integer] The length of the rotation.
      # @param edit_params - length_unit [String] The unit of the rotation length. (One of 'hours', days', 'weeks')
      # @param edit_params - starts_at [DateTime] The datetime the rotation starts on.
      # @param edit_params - ends_at [DateTime] The datetime the rotation ends on.
      # @param edit_params - participants [Array<hash>] An array of hashes defining participants of the on-call rotations.
      # @option opts  - user [User] The user who is part of the rotation
      # @option opts  - color_palette [String] The color palette to assign to the on-call user, for example: "blue".
      # @option opts  - color_weight [String] The color weight to assign to for the on-call user, for example "500". Max 4 chars.
      def initialize(oncall_rotation, user, edit_params)
        super(project: oncall_rotation.project, current_user: user, params: edit_params)

        @oncall_rotation = oncall_rotation
        @participants_params = params.delete(:participants)
      end

      def execute
        return error_no_license unless available?
        return error_no_permissions unless allowed?

        if participants_params
          return error_too_many_participants if participants_params.size > MAXIMUM_PARTICIPANTS
          return error_duplicate_participants if duplicated_users?
          return error_participants_without_permission if users_without_permissions?
        end

        ensure_rotation_is_up_to_date

        OncallRotation.transaction do
          oncall_rotation.update!(params)

          save_participants!
          save_current_shift!

          success(oncall_rotation.reset)
        end

      rescue ActiveRecord::RecordInvalid => err
        error_in_validation(err.record)
      end

      private

      attr_reader :oncall_rotation, :participants_params

      def save_participants!
        return if participants_params.nil?

        super

        oncall_rotation.touch
      end

      def error_no_permissions
        error('You have insufficient permissions to edit an on-call rotation in this project')
      end
    end
  end
end
