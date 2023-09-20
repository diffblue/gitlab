# frozen_string_literal: true

module ResolvesOrchestrationPolicy
  extend ActiveSupport::Concern

  POLICY_YAML_ATTRIBUTES = %i[name description enabled actions rules approval_settings].freeze

  included do
    include Gitlab::Graphql::Authorize::AuthorizeResource

    calls_gitaly!

    alias_method :project, :object
  end

  private

  def edit_path(policy, type)
    id = CGI.escape(policy[:name])
    if policy[:namespace]
      Rails.application.routes.url_helpers.edit_group_security_policy_url(
        policy[:namespace], id: id, type: type
      )
    else
      Rails.application.routes.url_helpers.edit_project_security_policy_url(
        policy[:project], id: id, type: type
      )
    end
  end
end
