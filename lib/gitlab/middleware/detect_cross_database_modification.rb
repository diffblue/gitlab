# frozen_string_literal: true

module Gitlab
  module Middleware
    class DetectCrossDatabaseModification
      def initialize(app)
        @app = app
      end

      def call(env)
        if Feature.enabled?(:detect_cross_database_modification, default_enabled: :yaml)
          ::Gitlab::Database::PreventCrossDatabaseModification.with_cross_database_modification_prevented(log_only: true) do
            @app.call(env)
          end
        else
          @app.call(env)
        end
      end
    end
  end
end
