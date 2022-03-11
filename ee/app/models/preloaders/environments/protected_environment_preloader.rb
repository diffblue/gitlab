# frozen_string_literal: true

module Preloaders
  module Environments
    class ProtectedEnvironmentPreloader
      attr_reader :environments

      def initialize(environments)
        @environments = environments

        if environments.map(&:project_id).uniq.size > 1
          raise 'This preloader supports only environments in the same project'
        end
      end

      def execute
        return if environments.empty?

        project = environments.first.project
        project_id = project.id
        group_ids = project.ancestors_upto_ids

        names = environments.map(&:name)
        tiers = environments.map(&:tier)

        project_protected_environments = ProtectedEnvironment.preload(:deploy_access_levels)
                                                             .where(project_id: project_id, name: names)
                                                             .index_by(&:name)
        group_protected_environments = ProtectedEnvironment.preload(:deploy_access_levels)
                                                           .where(group_id: group_ids, name: tiers)
                                                           .index_by(&:name)

        environments.each do |environment|
          protected_environments ||= []
          protected_environments << project_protected_environments[environment.name]
          protected_environments << group_protected_environments[environment.tier]
          environment.associated_protected_environments = protected_environments.flatten.compact
        end
      end
    end
  end
end
