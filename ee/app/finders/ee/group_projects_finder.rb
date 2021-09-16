# frozen_string_literal: true

module EE
  # GroupProjectsFinder
  #
  # Extends GroupProjectsFinder
  #
  # Added arguments:
  #   params:
  #     with_security_reports: boolean
  module GroupProjectsFinder
    extend ::Gitlab::Utils::Override

    override :filter_projects
    def filter_projects(collection)
      collection = super(collection)
      by_security_scans_presence(collection)
    end

    def by_security_scans_presence(collection)
      if params[:with_security_reports] && group.licensed_feature_available?(:security_dashboard)
        collection.with_security_scans
      else
        collection
      end
    end
  end
end
