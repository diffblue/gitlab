# frozen_string_literal: true

module Elastic
  class Migration
    include Elastic::MigrationOptions
    include Elastic::MigrationState

    attr_reader :version

    def initialize(version)
      @version = version
    end

    def migrate
      raise NotImplementedError, 'Please extend Elastic::Migration'
    end

    def completed?
      raise NotImplementedError, 'Please extend Elastic::Migration'
    end

    def space_required_bytes
      raise NotImplementedError, 'Please extend Elastic::Migration'
    end

    def obsolete?
      false
    end

    private

    def helper
      @helper ||= Gitlab::Elastic::Helper.default
    end

    def client
      helper.client
    end

    def migration_record
      Elastic::DataMigrationService[version]
    end

    def fail_migration_halt_error!(options = {})
      log "Halting migration with #{options}"

      migration_record.fail(options)
    end

    def log(message)
      logger.info "[Elastic::Migration: #{self.version}] #{message}"
    end

    def log_warn(message)
      logger.warn "[Elastic::Migration: #{self.version}] #{message}"
    end

    def log_raise(message)
      logger.error "[Elastic::Migration: #{self.version}] #{message}"
      raise message
    end

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end
  end
end
