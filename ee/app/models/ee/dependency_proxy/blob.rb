# frozen_string_literal: true

module EE
  module DependencyProxy
    module Blob
      extend ActiveSupport::Concern

      def log_geo_deleted_event
        # Keep empty for now. Should be addressed in future
        # by https://gitlab.com/gitlab-org/gitlab/-/issues/259694
      end
    end
  end
end
