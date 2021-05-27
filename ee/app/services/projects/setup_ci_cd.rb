# frozen_string_literal: true

module Projects
  class SetupCiCd < BaseService
    def execute
      return if project.import_url.blank?

      update_project
      disable_project_features
    end

    private

    def update_project
      project.update(
        mirror:                              true,
        mirror_trigger_builds:               true,
        mirror_overwrites_diverged_branches: true,
        only_mirror_protected_branches:      false,
        mirror_user_id:                      current_user.id
      )
    end

    def disable_project_features
      project.project_feature.update(
        issues_access_level:             ProjectFeature::DISABLED,
        merge_requests_access_level:     ProjectFeature::DISABLED,
        wiki_access_level:               ProjectFeature::DISABLED,
        snippets_access_level:           ProjectFeature::DISABLED,
        container_registry_access_level: ProjectFeature::DISABLED
      )
    end
  end
end
