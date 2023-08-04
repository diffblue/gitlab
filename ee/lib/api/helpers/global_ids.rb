# frozen_string_literal: true

module API
  module Helpers
    module GlobalIds
      UNKNOWN_ID = 'unknown'

      # Generates a globally unique (instance_id, user_id) pair. This allows us to
      # anonymously identify even self-managed users and instances that make requests
      # into GitLab infrastructure.
      class Generator
        def generate(user)
          instance_id = instance_id_or_unknown
          user_id = user_id_or_unknown(instance_id, user)

          [instance_id, user_id]
        end

        private

        def instance_id_or_unknown
          ::Gitlab::CurrentSettings.uuid.presence || GITLAB_INSTANCE_UUID_NOT_SET
        end

        def user_id_or_unknown(instance_id, user)
          user_id = user&.id

          return UNKNOWN_ID unless user_id
          raise ArgumentError, 'must pass a user instance' unless user.is_a?(User)

          Gitlab::CryptoHelper.sha256("#{instance_id}#{user_id}")
        end
      end

      def global_instance_and_user_id_for(user)
        Generator.new.generate(user)
      end
    end
  end
end
