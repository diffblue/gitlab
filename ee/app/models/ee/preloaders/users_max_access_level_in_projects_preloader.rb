# frozen_string_literal: true

module EE
  module Preloaders
    module UsersMaxAccessLevelInProjectsPreloader
      extend ::Gitlab::Utils::Override

      private

      override :preload_users_namespace_bans
      def preload_users_namespace_bans(users)
        ActiveRecord::Associations::Preloader.new.preload(users, :namespace_bans)
      end
    end
  end
end
