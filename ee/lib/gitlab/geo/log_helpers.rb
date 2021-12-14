# frozen_string_literal: true

module Gitlab
  module Geo
    module LogHelpers
      SIDEKIQ_JID_LENGTH = 24

      def log_info(message, details = {})
        data = base_log_data(message)
        data.merge!(details) if details
        geo_logger.info(data)
      end

      def log_error(message, error = nil, details = {})
        data = base_log_data(message)
        data[:error] = error.to_s if error
        data.merge!(details) if details
        geo_logger.error(data)
      end

      def log_debug(message, details = {})
        data = base_log_data(message)
        data.merge!(details) if details
        geo_logger.debug(data)
      end

      protected

      def base_log_data(message)
        {
          class: self.class.name,
          host: Gitlab.config.gitlab.host,
          message: message,
          job_id: get_sidekiq_job_id
        }.merge(extra_log_data).compact
      end

      # Intended to be overridden elsewhere
      def extra_log_data
        {}
      end

      def geo_logger
        Gitlab::Geo::Logger
      end

      def get_sidekiq_job_id
        context_data = Thread.current[:sidekiq_context]&.first
        return unless context_data

        index = context_data.index('JID-')
        return unless index

        context_data[index + 4..]
      end
    end
  end
end
