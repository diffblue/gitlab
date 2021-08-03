# frozen_string_literal: true
module ProtectedEnvironments
  class BaseService < ::BaseContainerService
    include Gitlab::Utils::StrongMemoize

    protected

    def sanitized_params
      params.dup.tap do |sanitized_params|
        sanitized_params[:deploy_access_levels_attributes] =
          filter_valid_deploy_access_level_attributes(sanitized_params[:deploy_access_levels_attributes])
      end
    end

    private

    def filter_valid_deploy_access_level_attributes(attributes)
      return unless attributes

      attributes.select { |attribute| valid_attribute?(attribute) }
    end

    def valid_attribute?(attribute)
      keys = attribute.slice(:access_level, :group_id, :user_id).keys
      return false unless keys.count == 1

      # If it's a destroy request, any group/user IDs are allowed to be passed,
      # so that users who are no longer project members can be removed from the access list.
      # `has_destroy_flag?` is defined in `ActiveRecord::NestedAttributes`.
      return true if ProtectedEnvironment::DeployAccessLevel.new.send(:has_destroy_flag?, attribute) # rubocop:disable GitlabSecurity/PublicSend

      if attribute[:group_id].present?
        qualified_group_ids.include?(attribute[:group_id])
      elsif attribute[:user_id].present?
        qualified_user_ids.include?(attribute[:user_id])
      else
        true
      end
    end

    def qualified_group_ids
      strong_memoize(:qualified_group_ids) do
        if project_container?
          container.invited_groups
        elsif group_container?
          container.self_and_descendants
        end.pluck_primary_key.to_set
      end
    end

    def qualified_user_ids
      strong_memoize(:qualified_user_ids) do
        user_ids = params[:deploy_access_levels_attributes].each.with_object([]) do |attribute, user_ids|
          user_ids << attribute[:user_id] if attribute[:user_id].present?
          user_ids
        end

        if project_container?
          container.project_authorizations
            .visible_to_user_and_access_level(user_ids, Gitlab::Access::DEVELOPER)
        elsif group_container?
          container.members_with_parents.owners_and_maintainers
        end.pluck_user_ids.to_set
      end
    end
  end
end
