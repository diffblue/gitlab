# frozen_string_literal: true

module EE
  module TemplateFinder
    extend ::Gitlab::Utils::Override

    CUSTOM_TEMPLATES = HashWithIndifferentAccess.new(
      dockerfiles: ::Gitlab::Template::CustomDockerfileTemplate,
      gitignores: ::Gitlab::Template::CustomGitignoreTemplate,
      gitlab_ci_ymls: ::Gitlab::Template::CustomGitlabCiYmlTemplate,
      issues: ::Gitlab::Template::IssueTemplate,
      merge_requests: ::Gitlab::Template::MergeRequestTemplate
    ).freeze

    attr_reader :custom_templates
    private :custom_templates

    def initialize(type, project, *args, &blk)
      super

      if CUSTOM_TEMPLATES.key?(type)
        finder = CUSTOM_TEMPLATES.fetch(type)
        @custom_templates = ::Gitlab::CustomFileTemplates.new(finder, project)
      end
    end

    override :execute
    def execute
      return super if custom_templates.nil? || !custom_templates.enabled?

      if params[:name]
        custom_templates.find(params[:name], params[:source_template_project_id]) || super
      else
        custom_templates.all + super
      end
    end

    override :template_names
    def template_names
      return super if custom_templates.nil? || !custom_templates.enabled?

      # on custom templates we do want to fetch all template names as this will iterate through inherited templates
      # from ancestor group levels
      custom_templates.all_template_names.merge(super)
    end
  end
end
