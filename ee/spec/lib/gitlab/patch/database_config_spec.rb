# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::DatabaseConfig do
  describe '#database_configuration' do
    let(:configuration) { Rails::Application::Configuration.new(Rails.root) }

    before do
      # The `AS::ConfigurationFile` calls `read` in `def initialize`
      # thus we cannot use `allow_next_instance_of`
      # rubocop:disable RSpec/AnyInstanceOf
      allow_any_instance_of(ActiveSupport::ConfigurationFile)
        .to receive(:read).with(Rails.root.join('config/database.yml')).and_return(database_yml)
      # rubocop:enable RSpec/AnyInstanceOf
    end

    shared_examples 'hash containing main: connection name' do
      it 'returns a hash containing only main:' do
        database_configuration = configuration.database_configuration

        expect(database_configuration).to match(
          "production" => { "main" => a_hash_including("adapter") },
          "development" => { "main" => a_hash_including("adapter" => "postgresql") },
          "test" => { "main" => a_hash_including("adapter" => "postgresql") }
        )
      end
    end

    shared_examples 'hash containing both main: and geo: connection names' do
      it 'returns a hash containing both main: and geo:' do
        database_configuration = configuration.database_configuration

        expect(database_configuration).to match(
          "production" => { "main" => a_hash_including("adapter"), "geo" => a_hash_including("adapter", "migrations_paths" => ["ee/db/geo/migrate", "ee/db/geo/post_migrate"], "schema_migrations_path" => "ee/db/geo/schema_migrations") },
          "development" => { "main" => a_hash_including("adapter"), "geo" => a_hash_including("adapter" => "postgresql", "migrations_paths" => ["ee/db/geo/migrate", "ee/db/geo/post_migrate"], "schema_migrations_path" => "ee/db/geo/schema_migrations") },
          "test" => { "main" => a_hash_including("adapter"), "geo" => a_hash_including("adapter" => "postgresql", "migrations_paths" => ["ee/db/geo/migrate", "ee/db/geo/post_migrate"], "schema_migrations_path" => "ee/db/geo/schema_migrations") }
        )
      end

      context 'when SKIP_POST_DEPLOYMENT_MIGRATIONS environment variable set' do
        before do
          stub_env('SKIP_POST_DEPLOYMENT_MIGRATIONS', 'true')
        end

        it 'does not include Geo post deployment migrations path' do
          database_configuration = configuration.database_configuration

          expect(database_configuration).to match(
            "production" => { "main" => a_hash_including("adapter"), "geo" => a_hash_including("adapter", "migrations_paths" => ["ee/db/geo/migrate"], "schema_migrations_path" => "ee/db/geo/schema_migrations") },
            "development" => { "main" => a_hash_including("adapter"), "geo" => a_hash_including("adapter" => "postgresql", "migrations_paths" => ["ee/db/geo/migrate"], "schema_migrations_path" => "ee/db/geo/schema_migrations") },
            "test" => { "main" => a_hash_including("adapter"), "geo" => a_hash_including("adapter" => "postgresql", "migrations_paths" => ["ee/db/geo/migrate"], "schema_migrations_path" => "ee/db/geo/schema_migrations") }
          )
        end
      end
    end

    context 'when config/database.yml does not contain Geo settings' do
      let(:database_yml) do
        <<-EOS
            production:
              main:
                adapter: postgresql
                encoding: unicode
                database: gitlabhq_production
                username: git
                password: "secure password"
                host: localhost

            development:
              main:
                adapter: postgresql
                encoding: unicode
                database: gitlabhq_development
                username: postgres
                password: "secure password"
                host: localhost
                variables:
                  statement_timeout: 15s

            test: &test
              main:
                adapter: postgresql
                encoding: unicode
                database: gitlabhq_test
                username: postgres
                password:
                host: localhost
                prepared_statements: false
                variables:
                  statement_timeout: 15s
        EOS
      end

      include_examples 'hash containing main: connection name'
    end

    context 'when config/database.yml contains Geo settings' do
      let(:database_yml) do
        <<-EOS
            production:
              main:
                adapter: postgresql
                encoding: unicode
                database: gitlabhq_production
                username: git
                password: "secure password"
                host: localhost
              geo:
                adapter: postgresql
                encoding: unicode
                database: gitlabhq_geo_production
                username: git
                password: "secure password"
                host: localhost

            development:
              main:
                adapter: postgresql
                encoding: unicode
                database: gitlabhq_development
                username: postgres
                password: "secure password"
                host: localhost
                variables:
                  statement_timeout: 15s
              geo:
                adapter: postgresql
                encoding: unicode
                database: gitlabhq_geo_development
                username: postgres
                password: "secure password"
                host: localhost
                variables:
                  statement_timeout: 15s

            test: &test
              main:
                adapter: postgresql
                encoding: unicode
                database: gitlabhq_test
                username: postgres
                password:
                host: localhost
                prepared_statements: false
                variables:
                  statement_timeout: 15s
              geo:
                adapter: postgresql
                encoding: unicode
                database: gitlabhq_geo_test
                username: postgres
                password:
                host: localhost
                prepared_statements: false
                variables:
                  statement_timeout: 15s
        EOS
      end

      include_examples 'hash containing both main: and geo: connection names'
    end
  end
end
