# frozen_string_literal: true

module API
  module Admin
    module Search
      class Migrations < ::API::Base # rubocop:disable Search/NamespacedClass
        feature_category :global_search
        urgency :low

        helpers do
          def ensure_elasticsearch_indexing_enabled!
            bad_request!('indexing is not enabled') unless ::Gitlab::CurrentSettings.elasticsearch_indexing?
          end
        end

        before do
          authenticated_as_admin!
          ensure_elasticsearch_indexing_enabled!
        end

        namespace 'admin' do
          resources 'search/migrations' do
            desc 'Lists all advanced search migrations' do
              failure [
                { code: 401, message: '401 Unauthorized' },
                { code: 403, message: '403 Forbidden' },
                { code: 404, message: '404 Not found' }
              ]
            end
            get do
              migrations = Elastic::DataMigrationService.migrations

              present(migrations, with: ::API::Entities::Search::Migration)
            end
          end

          resources 'search/migrations/:migration_id' do
            desc 'Get a migration by version or name' do
              success ::API::Entities::Search::Migration
              failure [
                { code: 401, message: '401 Unauthorized' },
                { code: 403, message: '403 Forbidden' },
                { code: 404, message: '404 Not found' }
              ]
            end
            params do
              requires :migration_id,
                types: [Integer, String],
                desc: 'The version or name of the search migration'
            end
            get do
              name_or_version = params[:migration_id]
              migration = if name_or_version.is_a?(Numeric)
                            Elastic::DataMigrationService[name_or_version]
                          else
                            Elastic::DataMigrationService.find_by_name(name_or_version)
                          end

              not_found!('migration not found') if migration.nil?

              present(migration, with: ::API::Entities::Search::Migration)
            end
          end
        end
      end
    end
  end
end
