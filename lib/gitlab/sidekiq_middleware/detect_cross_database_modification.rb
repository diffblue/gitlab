# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class DetectCrossDatabaseModification
      def call(worker, job, queue)
        if Feature.enabled?(:detect_cross_database_modification, default_enabled: :yaml)
          ::Gitlab::Database::PreventCrossDatabaseModification.with_cross_database_modification_prevented(log_only: true) do
            yield
          end
        else
          yield
        end
      end
    end
  end
end
