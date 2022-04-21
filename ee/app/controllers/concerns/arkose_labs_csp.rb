# frozen_string_literal: true

module ArkoseLabsCSP
  extend ActiveSupport::Concern

  included do
    content_security_policy do |policy|
      next unless Feature.enabled?(:arkose_labs_login_challenge)

      default_script_src = policy.directives['script-src'] || policy.directives['default-src']
      script_src_values = Array.wrap(default_script_src) | ["https://client-api.arkoselabs.com"]
      policy.script_src(*script_src_values)

      default_frame_src = policy.directives['frame-src'] || policy.directives['default-src']
      frame_src_values = Array.wrap(default_frame_src) | ['https://client-api.arkoselabs.com']
      policy.frame_src(*frame_src_values)
    end
  end
end
