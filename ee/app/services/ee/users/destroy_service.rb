# frozen_string_literal: true

module EE
  module Users
    module DestroyService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(user, options = {})
        result = super(user, options) do |delete_user|
          mirror_cleanup(delete_user)
          oncall_rotations_cleanup(delete_user)
        end

        log_audit_event(user) if result.try(:destroyed?)

        result
      end

      def mirror_cleanup(user)
        user_mirrors = ::Project.where(mirror_user: user) # rubocop: disable CodeReuse/ActiveRecord

        user_mirrors.find_each do |mirror|
          mirror.update(mirror: false, mirror_user: nil)
          ::Gitlab::ErrorTracking.track_exception(
            RuntimeError.new('Disabled mirroring'),
            user_id: user.id,
            project_id: mirror.id
          )

          ::NotificationService.new.mirror_was_disabled(mirror, user.name)
        end
      end

      def oncall_rotations_cleanup(user)
        ::IncidentManagement::OncallRotations::RemoveParticipantsService.new(
          user.oncall_rotations,
          user,
          false
        ).execute
      end

      private

      def first_mirror_owner(user, mirror)
        mirror_owners = mirror.team.owners
        mirror_owners -= [user]

        mirror_owners.first
      end

      def log_audit_event(user)
        ::AuditEventService.new(
          current_user,
          user,
          action: :destroy
        ).for_user.security_event
      end
    end
  end
end
