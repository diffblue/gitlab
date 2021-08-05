# frozen_string_literal: true

# This module is intended to centralize all database access to the secondary
# tracking database for Geo.
module Geo
  class TrackingBase < ApplicationRecord
    self.abstract_class = true

    NOT_CONFIGURED_MSG     = 'Geo secondary database is not configured'
    SecondaryNotConfigured = Class.new(StandardError)

    if ::Gitlab::Geo.geo_database_configured?
      # Mark current model as a `connection_class`
      # This is the behavior when executing `connects_to`
      # which indicates that given class is holding a connection object
      # and should be treated accordingly.
      self.connection_class = true

      establish_connection Rails.configuration.geo_database
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
  end
end
