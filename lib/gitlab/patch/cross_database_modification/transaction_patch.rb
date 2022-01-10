# frozen_string_literal: true

module Gitlab
  module Patch
    module CrossDatabaseModification
      module TransactionPatch
        extend ActiveSupport::Concern

        def add_gitlab_schema(schema)
          @gitlab_schema = schema # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end

        def materialize!
          annotate_with_gitlab_schema do
            super
          end
        end

        def rollback
          annotate_with_gitlab_schema do
            super
          end
        end

        def commit
          annotate_with_gitlab_schema do
            super
          end
        end

        private

        attr_reader :gitlab_schema

        # Set marginalia comment to track cross-db transactions
        # for BEGIN/SAVEPOINT/COMMIT/RELEASE/ROLLBACK
        def annotate_with_gitlab_schema
          if gitlab_schema
            Gitlab::Marginalia::Comment.with_gitlab_schema(gitlab_schema) do
              if ENV['CROSS_DB_MOD_DEBUG']
                debug_log(:gitlab_schema, gitlab_schema)

                Gitlab::BacktraceCleaner.clean_backtrace(caller).each do |line|
                  debug_log(:backtrace, line)
                end
              end

              yield
            end
          else
            yield
          end
        end

        def debug_log(label, line)
          msg = "CrossDatabaseModification #{label}:  --> #{line}"

          Rails.logger.debug(msg) # rubocop:disable Gitlab/RailsLogger
        end
      end
    end
  end
end
