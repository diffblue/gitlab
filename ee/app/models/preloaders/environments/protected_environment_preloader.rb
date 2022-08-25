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

      def execute(association_attributes)
        return if environments.empty?

        associated_protected_environments =
          ProtectedEnvironment.for_environments(environments).preload(association_attributes)

        project_protected_environments = associated_protected_environments.select(&:project_level?).index_by(&:name)
        group_protected_environments = associated_protected_environments.select(&:group_level?).index_by(&:name)

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
