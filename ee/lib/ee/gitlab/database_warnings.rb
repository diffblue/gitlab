# frozen_string_literal: true

module EE
  module Gitlab
    module DatabaseWarnings
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :check_postgres_version_and_print_warning
        def check_postgres_version_and_print_warning
          super
        rescue ::Geo::TrackingBase::SecondaryNotConfigured
          # ignore - happens when Rake tasks yet have to create a database, e.g. for testing
        end
      end
    end
  end
end
