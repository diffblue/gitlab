# frozen_string_literal: true

module SystemCheck
  module RakeTask
    # Used by gitlab:geo:check rake task
    module GeoTask
      extend RakeTaskHelpers

      def self.name
        'Geo'
      end

      def self.checks
        return secondary_checks if Gitlab::Geo.secondary? || Gitlab::Geo.current_node_misconfigured?

        common_checks
      end

      def self.common_checks
        [
          SystemCheck::Geo::LicenseCheck,
          SystemCheck::Geo::EnabledCheck,
          SystemCheck::Geo::CurrentNodeCheck,
          SystemCheck::Geo::HTTPCloneEnabledCheck,
          SystemCheck::Geo::ClocksSynchronizationCheck,
          SystemCheck::App::GitUserDefaultSSHConfigCheck,
          SystemCheck::Geo::AuthorizedKeysCheck,
          SystemCheck::Geo::AuthorizedKeysFlagCheck,
          SystemCheck::App::HashedStorageEnabledCheck,
          SystemCheck::App::HashedStorageAllProjectsCheck
        ]
      end

      def self.secondary_checks
        [
          SystemCheck::Geo::GeoDatabaseConfiguredCheck,
          SystemCheck::Geo::DatabaseReplicationEnabledCheck,
          SystemCheck::Geo::DatabaseReplicationWorkingCheck,
          SystemCheck::Geo::HttpConnectionCheck,
          SystemCheck::Geo::SshPortCheck
        ] + common_checks
      end
    end
  end
end
