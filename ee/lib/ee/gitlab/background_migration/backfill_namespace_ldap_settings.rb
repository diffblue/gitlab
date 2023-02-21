# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module BackfillNamespaceLdapSettings
        extend ::Gitlab::Utils::Override

        override :perform
        def perform
          each_sub_batch do |sub_batch|
            connection.execute(
              <<~SQL
                INSERT INTO namespace_ldap_settings
                (
                  namespace_id,
                  created_at,
                  updated_at,
                  sync_last_start_at,
                  sync_last_update_at,
                  sync_last_successful_at,
                  sync_error
                )
                SELECT namespaces.id,
                       Now(),
                       Now(),
                       namespaces.ldap_sync_last_sync_at,
                       namespaces.ldap_sync_last_update_at,
                       namespaces.ldap_sync_last_successful_update_at,
                       namespaces.ldap_sync_error
                FROM   namespaces
                WHERE  namespaces.id IN(#{sub_batch.select(:id).to_sql})
                ON CONFLICT DO NOTHING;
              SQL
            )
          end
        end
      end
    end
  end
end
