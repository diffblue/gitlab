# frozen_string_literal: true

module CrossModificationTransactionMixin
  extend ActiveSupport::Concern

  class_methods do
    def transaction(**options, &block)
      super(**options) do
        if connection.current_transaction.respond_to?(:add_gitlab_schema) && gitlab_schema
          connection.current_transaction.add_gitlab_schema(gitlab_schema)
        end

        yield
      end
    end

    def gitlab_schema
      case self.name
      when 'ActiveRecord::Base', 'ApplicationRecord'
        :gitlab_main
      when 'Ci::ApplicationRecord'
        :gitlab_ci
      else
        Gitlab::Database::GitlabSchema.table_schema(table_name) if table_name
      end
    end
  end
end

module TransactionGitlabSchemaMixin
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

ActiveRecord::Base.prepend(CrossModificationTransactionMixin) if Rails.env.test?
ActiveRecord::ConnectionAdapters::RealTransaction.prepend(TransactionGitlabSchemaMixin) if Rails.env.test?
ActiveRecord::ConnectionAdapters::SavepointTransaction.prepend(TransactionGitlabSchemaMixin) if Rails.env.test?
