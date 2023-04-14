# frozen_string_literal: true

module EE
  module BlobHelper
    extend ::Gitlab::Utils::Override

    override :vue_blob_app_data
    def vue_blob_app_data(project, blob, ref)
      super.merge({
        explain_code_available: ::Llm::ExplainCodeService.new(current_user, project).valid?.to_s
      })
    end
  end
end
