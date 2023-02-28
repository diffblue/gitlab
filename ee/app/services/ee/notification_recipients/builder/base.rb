# frozen_string_literal: true

module EE
  module NotificationRecipients
    module Builder
      module Base
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        private

        override :preload_users_namespace_bans
        def preload_users_namespace_bans(users)
          ActiveRecord::Associations::Preloader.new(records: users, associations: :namespace_bans).call # rubocop:disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
