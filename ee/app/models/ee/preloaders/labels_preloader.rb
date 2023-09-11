# frozen_string_literal: true

module EE
  module Preloaders
    module LabelsPreloader
      extend ::Gitlab::Utils::Override

      override :preload_all
      def preload_all
        super

        ActiveRecord::Associations::Preloader.new(
          records: group_labels,
          associations: { group: [:ip_restrictions, :saml_provider] }
        ).call

        ActiveRecord::Associations::Preloader.new(
          records: project_labels,
          associations: { project: [:group, :invited_groups] }
        ).call

        # preloading the root ancestors for the project labels for the authorizations checks
        project_groups = project_labels.filter_map(&:project).filter_map(&:group)

        return if project_groups.empty?

        ::Preloaders::GroupRootAncestorPreloader.new(project_groups).execute

        ActiveRecord::Associations::Preloader.new(
          records: project_groups.map(&:root_ancestor),
          associations: [:saml_provider]
        ).call
      end
    end
  end
end
