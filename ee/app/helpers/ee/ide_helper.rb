# frozen_string_literal: true

module EE
  module IdeHelper
    extend ::Gitlab::Utils::Override

    override :ide_data
    def ide_data(project:, fork_info:, params:)
      super.merge(
        'learn_gitlab_source' => ::Gitlab::Utils.to_boolean(params[:learn_gitlab_source]).to_s
      )
    end
  end
end
