# frozen_string_literal: true

module AppSec
  module Dast
    module Sites
      class FindOrCreateService < BaseService
        PermissionsError = Class.new(StandardError)

        def execute!(url:)
          raise PermissionsError, 'Insufficient permissions' unless allowed?

          DastSite.find_or_create_by!(project: project, url: url) # rubocop:disable CodeReuse/ActiveRecord
        end

        private

        def allowed?
          Ability.allowed?(current_user, :create_on_demand_dast_scan, project)
        end
      end
    end
  end
end
