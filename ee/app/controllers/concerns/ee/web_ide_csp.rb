# frozen_string_literal: true

module EE
  module WebIdeCSP
    extend ::Gitlab::Utils::Override

    # This is hardcoded for now, but will be configurable in https://gitlab.com/gitlab-org/gitlab/-/issues/412662
    CODE_SUGGESTIONS_URL = 'https://codesuggestions.gitlab.com/'

    override :include_web_ide_csp
    def include_web_ide_csp
      super

      return if request.content_security_policy.directives.blank?

      default_src = Array(request.content_security_policy.directives['default-src'] || [])
      request.content_security_policy.directives['connect-src'] ||= default_src
      request.content_security_policy.directives['connect-src'].concat([CODE_SUGGESTIONS_URL])
    end
  end
end
