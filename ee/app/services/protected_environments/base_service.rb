# frozen_string_literal: true
module ProtectedEnvironments
  class BaseService < ::BaseContainerService
    include Gitlab::Utils::StrongMemoize

    SANITIZABLE_KEYS = %i[deploy_access_levels_attributes approval_rules_attributes].freeze

    protected

    def sanitized_params
      params.dup.tap do |sanitized_params|
        SANITIZABLE_KEYS.each do |key|
          next unless sanitized_params.has_key?(key)

          sanitized_params[key] = filter_valid_authorizable_attributes(sanitized_params[key])
        end
      end
    end

    private

    def filter_valid_authorizable_attributes(attributes)
      return unless attributes

      attributes.select { |attribute| valid_attribute?(attribute) }
    end

    def valid_attribute?(attribute)
      # If it's a destroy request, any group/user IDs are allowed to be passed,
      # so that users who are no longer project members can be removed from the access list.
      # `has_destroy_flag?` is defined in `ActiveRecord::NestedAttributes`.
      return true if ProtectedEnvironments::DeployAccessLevel.new.send(:has_destroy_flag?, attribute) # rubocop:disable GitlabSecurity/PublicSend

      return false if attribute[:group_id].present? && qualified_group_ids.exclude?(attribute[:group_id])
      return false if attribute[:user_id].present? && qualified_user_ids.exclude?(attribute[:user_id])

      true
    end

    def qualified_group_ids
      strong_memoize(:qualified_group_ids) do
        if project_container?
          container.invited_groups
        elsif group_container?
          Group.from_union([container.self_and_descendants,
                            container.shared_with_groups])
        end.pluck_primary_key.to_set
      end
    end

    def qualified_user_ids
      strong_memoize(:qualified_user_ids) do
        user_ids = all_sanitizable_params.each.with_object([]) do |attribute, user_ids|
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

    def all_sanitizable_params
      params.values_at(*SANITIZABLE_KEYS).flatten.compact
    end
  end
end
