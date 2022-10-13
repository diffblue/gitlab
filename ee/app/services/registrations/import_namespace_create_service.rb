# frozen_string_literal: true

module Registrations
  class ImportNamespaceCreateService < BaseNamespaceCreateService
    def execute
      @group = Groups::CreateService.new(user, modified_group_params).execute

      if group.persisted?
        after_successful_group_creation(group_track_action: 'create_group_import')

        ServiceResponse.success(payload: { group: group })
      else
        @project = Project.new(namespace: group)

        ServiceResponse.error(message: 'Group failed to be created', payload: { group: group, project: project })
      end
    end
  end
end
