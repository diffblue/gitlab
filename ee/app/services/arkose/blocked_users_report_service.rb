# frozen_string_literal: true
module Arkose
  class BlockedUsersReportService
    NON_LEGIT_URL = 'https://customer-sessions.arkoselabs.com/nonlegit'

    def execute
      return true unless arkose_public_api_key && arkose_private_api_key

      sessions = UserCustomAttribute.sessions

      return true unless sessions.present?

      response = Gitlab::HTTP.perform_request(Net::HTTP::Post, NON_LEGIT_URL, body: body(sessions.map(&:value)))

      response.success?
    end

    def body(sessions)
      {
        publicKey: arkose_public_api_key,
        privateKey: arkose_private_api_key,
        sessions: sessions
      }.to_json
    end

    def arkose_public_api_key
      Gitlab::CurrentSettings.arkose_labs_public_api_key || ENV['ARKOSE_LABS_PUBLIC_KEY']
    end

    def arkose_private_api_key
      Gitlab::CurrentSettings.arkose_labs_private_api_key || ENV['ARKOSE_LABS_PRIVATE_KEY']
    end
  end
end
