# frozen_string_literal: true

module Arkose
  class Settings
    def self.arkose_public_api_key
      ::Gitlab::CurrentSettings.arkose_labs_public_api_key || ENV['ARKOSE_LABS_PUBLIC_KEY']
    end

    def self.arkose_private_api_key
      ::Gitlab::CurrentSettings.arkose_labs_private_api_key || ENV['ARKOSE_LABS_PRIVATE_KEY']
    end

    def self.arkose_labs_domain
      "#{::Gitlab::CurrentSettings.arkose_labs_namespace}-api.arkoselabs.com"
    end
  end
end
