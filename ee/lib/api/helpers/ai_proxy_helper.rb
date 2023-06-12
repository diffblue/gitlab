# frozen_string_literal: true

module API
  module Helpers
    module AiProxyHelper
      include Gitlab::Utils::StrongMemoize

      def with_proxy_ai_request
        if Gitlab.org_or_com?
          yield
        else
          # We are proxying request to SaaS using workhorse send_url
          header(*proxy_request.workhorse_headers)
          status :ok
          body ''
        end
      end

      private

      def proxy_request
        Gitlab::SelfManaged::ProxyRequest.new(request, ::Gitlab::CurrentSettings.ai_access_token)
      end
    end
  end
end
