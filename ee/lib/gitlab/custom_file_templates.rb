# frozen_string_literal: true

module Gitlab
  class CustomFileTemplates
    include ::Gitlab::Utils::StrongMemoize

    attr_reader :finder, :project

    def initialize(finder, project)
      @finder = finder
      @project = project
    end

    def enabled?
      instance_enabled? || namespace_enabled?
    end

    def all_template_names
      template_names = {}
      namespace_template_projects_hash.flat_map do |namespace, project|
        project_template_names = template_names_for(project).values.flatten

        next if project_template_names.blank?

        template_names[category_for(namespace)] = project_template_names
      end

      if instance_enabled?
        template_names[_('Instance')] = template_names_for(instance_template_project).values.flatten
      end

      template_names
    end

    def all
      by_namespace = namespace_template_projects_hash.flat_map do |namespace, project|
        templates_for(project, category_for(namespace))
      end

      by_instance =
        if instance_enabled?
          templates_for(instance_template_project, _('Instance'))
        else
          []
        end

      by_namespace + by_instance
    end

    def find(name, source_template_project_id = nil)
      namespace_template_projects_hash.each do |namespace, project|
        next if source_template_project_id && project&.id != source_template_project_id.to_i

        found = template_for(project, name, category_for(namespace))
        return found if found
      end

      return if source_template_project_id && instance_template_project&.id != source_template_project_id.to_i

      template_for(instance_template_project, name, _('Instance'))
    end

    private

    def instance_enabled?
      instance_template_project.present?
    end

    def namespace_enabled?
      namespace_template_projects_hash.present?
    end

    def instance_template_project
      strong_memoize(:instance_template_project) do
        if ::License.feature_available?(:custom_file_templates)
          ::Gitlab::CurrentSettings.file_template_project
        end
      end
    end

    def category_for(namespace)
      "Group #{namespace.full_name}"
    end

    # Template projects referenced by each group are included here. They are
    # ordered from most-specific to least-specific
    def namespace_template_projects_hash
      strong_memoize(:namespace_template_projects_hash) do
        next {} unless project.present?

        project
          .ancestors_upto(nil)
          .with_custom_file_templates
          .select { |namespace| namespace.checked_file_template_project }
          .index_with { |namespace| namespace.checked_file_template_project }
      end
    end

    def template_names_for(project)
      return [] unless project

      finder.template_names(project)
    end

    def templates_for(project, category)
      return [] unless project

      finder.all(project).map { |template| translate(template, project, category: category) }
    end

    def template_for(project, name, category)
      return unless project

      translate(finder.find(name, project), project, category: category)
    rescue ::Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
      nil
    end

    def translate(template, project, category:)
      return unless template

      template.category = category if category

      # License templates require special handling as the "vendored" licenses
      # are actually in a gem, not on disk like the rest of the templates. So,
      # all license templates use a shim that presents a unified interface.
      return template unless license_templates?

      LicenseTemplate.new(
        key: template.key,
        name: template.name,
        project: project,
        nickname: template.name,
        category: template.category,
        content: -> { template.content }
      )
    end

    def license_templates?
      finder == ::Gitlab::Template::CustomLicenseTemplate
    end
  end
end
