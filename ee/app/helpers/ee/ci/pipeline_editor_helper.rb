# frozen_string_literal: true

module EE
  module Ci
    module PipelineEditorHelper
      extend ::Gitlab::Utils::Override

      override :js_pipeline_editor_data
      def js_pipeline_editor_data(project)
        result = super
        chat = Ai::Project::Conversations.new(project, current_user)

        if chat.ci_config_chat_enabled? && current_user.can?(:create_pipeline, project)
          result["ai_chat_available"] = chat.ci_config_chat_enabled?.to_s
        end

        if project.licensed_feature_available?(:api_fuzzing)
          result.merge!(
            "api-fuzzing-configuration-path" => project_security_configuration_api_fuzzing_path(project),
            "dast-configuration-path" => project_security_configuration_dast_path(project)
          )
        end

        result
      end
    end
  end
end
