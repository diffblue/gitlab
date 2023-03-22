# frozen_string_literal: true

module EE
  module Preloaders
    module UsersMaxAccessLevelByProjectPreloader
      extend ::Gitlab::Utils::Override

      private

      override :preload_users_namespace_bans
      def preload_users_namespace_bans(users)
        ActiveRecord::Associations::Preloader.new(records: users, associations: :namespace_bans).call
      end
    end
  end
end
