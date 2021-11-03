# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::RestrictGitlabSchema, query_analyzers: false do
  let(:schema_class) { Class.new(Gitlab::Database::Migration[1.0]).include(described_class) }

  describe '#restrict_gitlab_migration' do
    it 'invalid schema raises exception' do
      expect { schema_class.restrict_gitlab_migration gitlab_schema: :gitlab_non_exisiting }
        .to raise_error /Unknown 'gitlab_schema:/
    end

    it 'does configure allowed_gitlab_schema' do
      schema_class.restrict_gitlab_migration gitlab_schema: :gitlab_main

      expect(schema_class.allowed_gitlab_schemas).to eq(%i[gitlab_main])
    end
  end

  context 'when executing migrations' do
    using RSpec::Parameterized::TableSyntax

    where do
      {
        "does create table in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            def change
              create_table :_test_table do |t|
                t.references :project, foreign_key: true, null: false
                t.timestamps_with_timezone null: false
              end
            end
          end,
          query_matcher: /CREATE TABLE "_test_table"/,
          expected: {
            main: :success,
            ci: :success
          }
        },
        "does add column to projects in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            def change
              add_column :projects, :__test_column, :integer
            end
          end,
          query_matcher: /ALTER TABLE "projects" ADD "__test_column" integer/,
          expected: {
            main: :success,
            ci: :success
          }
        },
        "does add column to ci_builds in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            def change
              add_column :ci_builds, :__test_column, :integer
            end
          end,
          query_matcher: /ALTER TABLE "ci_builds" ADD "__test_column" integer/,
          expected: {
            main: :success,
            ci: :success
          }
        },
        "does add index to projects in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            def change
              # Due to running in transactin we cannot use `add_concurrent_index`
              add_index :projects, :hidden
            end
          end,
          query_matcher: /CREATE INDEX/,
          expected: {
            main: :success,
            ci: :success
          }
        },
        "does add index to ci_builds in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            def change
              # Due to running in transactin we cannot use `add_concurrent_index`
              add_index :ci_builds, :tag, where: "type = 'Ci::Build'", name: 'index_ci_builds_on_tag_and_type_eq_ci_build'
            end
          end,
          query_matcher: /CREATE INDEX/,
          expected: {
            main: :success,
            ci: :success
          }
        },
        "does create trigger in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            include Gitlab::Database::SchemaHelpers

            def up
              create_trigger_function('_test_trigger_function', replace: true) do
                <<~SQL
                  RETURN NULL;
                SQL
              end
            end

            def down
              drop_function('_test_trigger_function')
            end
          end,
          query_matcher: /CREATE OR REPLACE FUNCTION/,
          expected: {
            main: :success,
            ci: :success
          }
        },
        "does attach loose foreign key trigger in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

            enable_lock_retries!

            def up
              track_record_deletions(:audit_events)
            end

            def down
              untrack_record_deletions(:audit_events)
            end
          end,
          query_matcher: /CREATE TRIGGER/,
          expected: {
            main: :success,
            ci: :success
          }
        },
        "does raise exception on insert into software_licenses without restrict" => {
          migration: ->(klass) do
            def up
              software_license_class.create!(name: 'aaa')
            end

            def down
              software_license_class.where(name: 'aaa').delete_all
            end

            def software_license_class
              Class.new(ActiveRecord::Base) do
                self.table_name = 'software_licenses'
              end
            end
          end,
          query_matcher: /INSERT INTO "software_licenses"/,
          expected: {
            main: :dml_not_allowed,
            ci: :dml_not_allowed
          }
        },
        "does raise exception when accessing tables outside of gitlab_main" => {
          migration: ->(klass) do
            restrict_gitlab_migration gitlab_schema: :gitlab_main

            def up
              ci_instance_variables_class.create!(variable_type: 1, key: 'aaa')
            end

            def down
              ci_instance_variables_class.delete_all
            end

            def ci_instance_variables_class
              Class.new(ActiveRecord::Base) do
                self.table_name = 'ci_instance_variables'
              end
            end
          end,
          query_matcher: /INSERT INTO "ci_instance_variables"/,
          expected: {
            main: :dml_access_denied,
            ci: :skipped
          }
        },
        "does insert data into software_licenses of gitlab_main, but skips gitlab_ci with restrict" => {
          migration: ->(klass) do
            restrict_gitlab_migration gitlab_schema: :gitlab_main

            def up
              software_license_class.create!(name: 'aaa')
            end

            def down
              software_license_class.where(name: 'aaa').delete_all
            end

            def software_license_class
              Class.new(ActiveRecord::Base) do
                self.table_name = 'software_licenses'
              end
            end
          end,
          query_matcher: /INSERT INTO "software_licenses"/,
          expected: {
            main: :success,
            ci: :skipped
          }
        },
        "does allow modifying gitlab_shared without restrict" => {
          migration: ->(klass) do
            def up
              detached_partitions_class.create!(drop_after: Time.current, table_name: '_test_table')
            end

            def down
            end

            def detached_partitions_class
              Class.new(ActiveRecord::Base) do
                self.table_name = 'detached_partitions'
              end
            end
          end,
          query_matcher: /INSERT INTO "detached_partitions"/,
          expected: {
            main: :success,
            ci: :success
          }
        },
        "does allow modifying gitlab_shared with restrict on gitlab_shared" => {
          migration: ->(klass) do
            restrict_gitlab_migration gitlab_schema: :gitlab_shared

            def up
              detached_partitions_class.create!(drop_after: Time.current, table_name: '_test_table')
            end

            def down
            end

            def detached_partitions_class
              Class.new(ActiveRecord::Base) do
                self.table_name = 'detached_partitions'
              end
            end
          end,
          query_matcher: /INSERT INTO "detached_partitions"/,
          expected: {
            main: :success,
            ci: :success
          }
        },
        "does allow modifying gitlab_shared with restrict on gitlab_main" => {
          migration: ->(klass) do
            restrict_gitlab_migration gitlab_schema: :gitlab_main

            def up
              detached_partitions_class.create!(drop_after: Time.current, table_name: '_test_table')
            end

            def down
            end

            def detached_partitions_class
              Class.new(ActiveRecord::Base) do
                self.table_name = 'detached_partitions'
              end
            end
          end,
          query_matcher: /INSERT INTO "detached_partitions"/,
          expected: {
            main: :success,
            ci: :skipped
          }
        },
        "does update data in batches of gitlab_main, but skips gitlab_ci with restrict" => {
          migration: ->(klass) do
            restrict_gitlab_migration gitlab_schema: :gitlab_main

            def up
              update_column_in_batches(:projects, :archived, true) do |table, query|
                query.where(table[:archived].eq(false)) # rubocop:disable CodeReuse/ActiveRecord
              end
            end

            def down
              # no-op
            end
          end,
          query_matcher: /FROM "projects"/,
          expected: {
            main: :success,
            ci: :skipped
          }
        },
        "does not allow executing mixed DDL and DML migrations without restrict" => {
          migration: ->(klass) do
            def up
              execute('UPDATE projects SET hidden=false')
              add_index(:projects, :hidden, name: 'test_index')
            end

            def down
              # no-op
            end
          end,
          expected: {
            main: :dml_not_allowed,
            ci: :dml_not_allowed
          }
        },
        "does not allow executing mixed DDL and DML migrations with restrict" => {
          migration: ->(klass) do
            restrict_gitlab_migration gitlab_schema: :gitlab_main

            def up
              execute('UPDATE projects SET hidden=false')
              add_index(:projects, :hidden, name: 'test_index')
            end

            def down
              # no-op
            end
          end,
          expected: {
            main: :ddl_not_allowed,
            ci: :skipped
          }
        },
        "does raise exception when doing background migrations without restrict" => {
          migration: ->(klass) do
            def up
              queue_background_migration_jobs_by_range_at_intervals(
                define_batchable_model('vulnerability_occurrences'),
                'RemoveDuplicateVulnerabilitiesFindings',
                2.minutes.to_i,
                batch_size: 5_000
              )
            end

            def down
              # no-op
            end
          end,
          expected: {
            main: :dml_not_allowed,
            ci: :dml_not_allowed
          }
        },
        "does schedule background migrations on gitlab_main, but skips on gitlab_ci with restrict" => {
          migration: ->(klass) do
            restrict_gitlab_migration gitlab_schema: :gitlab_main

            def up
              queue_background_migration_jobs_by_range_at_intervals(
                define_batchable_model('vulnerability_occurrences'),
                'RemoveDuplicateVulnerabilitiesFindings',
                2.minutes.to_i,
                batch_size: 5_000
              )
            end

            def down
              # no-op
            end
          end,
          query_matcher: /FROM "vulnerability_occurrences"/,
          expected: {
            main: :success,
            ci: :skipped
          }
        }
      }
    end

    with_them do
      let(:migration_class) { Class.new(schema_class, &migration) }

      Gitlab::Database.database_base_models.each do |db_config_name, model|
        context "for #{db_config_name}" do
          around do |example|
            with_reestablished_active_record_base do
              reconfigure_db_connection(model: ActiveRecord::Base, config_model: model)

              example.run
            end
          end

          before do
            allow_next_instance_of(migration_class) do |migration|
              allow(migration).to receive(:transaction_open?).and_return(false)
            end
          end

          it "runs migrate :up and :down" do
            # In some cases (for :down) we ignore error and expect no other errors
            case expected[db_config_name.to_sym]
            when :success
              expect { migration_class.migrate(:up) }.to make_queries_matching(query_matcher)
              expect { migration_class.migrate(:down) }.not_to make_queries_matching(query_matcher)

            when :dml_not_allowed
              expect { migration_class.migrate(:up) }.to raise_error(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DMLNotAllowedError)
              expect { ignore_error(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DMLNotAllowedError) { migration_class.migrate(:down) } }.not_to raise_error

            when :dml_access_denied
              expect { migration_class.migrate(:up) }.to raise_error(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DMLAccessDeniedError)
              expect { ignore_error(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DMLAccessDeniedError) { migration_class.migrate(:down) } }.not_to raise_error

            when :ddl_not_allowed
              expect { migration_class.migrate(:up) }.to raise_error(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DDLNotAllowedError)
              expect { ignore_error(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DDLNotAllowedError) { migration_class.migrate(:down) } }.not_to raise_error

            when :skipped
              expect { migration_class.migrate(:up) }.to raise_error(Gitlab::Database::MigrationHelpers::RestrictGitlabSchema::MigrationSkippedError)
              expect { migration_class.migrate(:down) }.to raise_error(Gitlab::Database::MigrationHelpers::RestrictGitlabSchema::MigrationSkippedError)
            end
          end

          def ignore_error(error)
            yield
          rescue error
          end
        end
      end
    end
  end
end
