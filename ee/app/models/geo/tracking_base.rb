# frozen_string_literal: true

# This module is intended to centralize all database access to the secondary
# tracking database for Geo.
module Geo
  class TrackingBase < ApplicationRecord
    self.abstract_class = true

    NOT_CONFIGURED_MSG     = 'Geo secondary database is not configured'
    SecondaryNotConfigured = Class.new(StandardError)

    if ::Gitlab::Geo.geo_database_configured?
      connects_to database: { writing: :geo, reading: :geo }
    end

    def self.connected?
      return false unless ::Gitlab::Geo.geo_database_configured?

      connection_handler.connected?(connection_specification_name)
    end

    def self.connection
      unless ::Gitlab::Geo.geo_database_configured?
        message = NOT_CONFIGURED_MSG
        message = "#{message}\nIn the GDK root, try running `make geo-setup`" if Rails.env.development?
        raise SecondaryNotConfigured, message
      end

      # Don't call super because LoadBalancing::ActiveRecordProxy will intercept it
      retrieve_connection
    rescue ActiveRecord::NoDatabaseError
      raise SecondaryNotConfigured, NOT_CONFIGURED_MSG
    end

    class SchemaMigration < TrackingBase
      class << self
        def all_versions
          order(:version).pluck(:version)
        end
      end
    end
  end
end
