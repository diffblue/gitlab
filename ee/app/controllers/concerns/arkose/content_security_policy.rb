# frozen_string_literal: true

module Arkose
  module ContentSecurityPolicy
    extend ActiveSupport::Concern

    included do
      content_security_policy do |policy|
        next unless policy.directives.present?

        allow_for_login = Feature.enabled?(:arkose_labs_login_challenge)
        allow_for_signup = Feature.enabled?(:arkose_labs_signup_challenge)
        allow_for_identity_verification = Feature.enabled?(:arkose_labs_oauth_signup_challenge)

        next unless allow_for_login || allow_for_signup || allow_for_identity_verification

        default_script_src = policy.directives['script-src'] || policy.directives['default-src']
        script_src_values = Array.wrap(default_script_src) | ["https://*.arkoselabs.com"]
        policy.script_src(*script_src_values)

        default_frame_src = policy.directives['frame-src'] || policy.directives['default-src']
        frame_src_values = Array.wrap(default_frame_src) | ['https://*.arkoselabs.com']
        policy.frame_src(*frame_src_values)
      end
    end
  end
end
