# frozen_string_literal: true

module Llm
  class ExecuteMethodService < BaseService
    # This list of methods will expand as we add more methods to support.
    # Could also be abstracted to another class specific to find the appropriate method service.
    METHODS = {
      explain_vulnerability: ::Llm::ExplainVulnerabilityService,
      summarize_comments: Llm::GenerateSummaryService,
      explain_code: Llm::ExplainCodeService,
      tanuki_bot: Llm::TanukiBotService,
      generate_test_file: Llm::GenerateTestFileService,
      generate_description: Llm::GenerateDescriptionService
    }.freeze

    def initialize(user, resource, method, options = {})
      super(user, resource, options)

      @method = method
    end

    def execute
      return error('Unknown method') unless METHODS.key?(method)

      result = METHODS[method].new(user, resource, options).execute

      track_snowplow_event(result)
      return success(result.payload) if result.success?

      error(result.message)
    end

    private

    attr_reader :method

    def track_snowplow_event(result)
      Gitlab::Tracking.event(
        self.class.to_s,
        "execute_llm_method",
        label: method.to_s,
        property: result.success? ? "success" : "error",
        user: user,
        namespace: namespace,
        project: project
      )
    end

    def namespace
      case resource
      when Group
        resource
      when Project
        resource.group
      when User
        nil
      else
        case resource&.resource_parent
        when Group
          resource.resource_parent
        when Project
          resource.resource_parent.group
        end
      end
    end

    def project
      if resource.is_a?(Project)
        resource
      elsif resource.is_a?(Group) || resource.is_a?(User)
        nil
      elsif resource&.resource_parent.is_a?(Project)
        resource.resource_parent
      end
    end
  end
end
