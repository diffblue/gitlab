# frozen_string_literal: true
module Arkose
  class BlockedUsersReportService
    NON_LEGIT_URL = 'https://customer-sessions.arkoselabs.com/nonlegit'

    def execute
      return true unless Settings.arkose_public_api_key && Settings.arkose_private_api_key

      sessions = UserCustomAttribute.sessions

      return true unless sessions.present?

      response = Gitlab::HTTP.perform_request(Net::HTTP::Post, NON_LEGIT_URL, body: body(sessions.map(&:value)))

      response.success?
    end

    def body(sessions)
      {
        publicKey: Settings.arkose_public_api_key,
        privateKey: Settings.arkose_private_api_key,
        sessions: sessions
      }.to_json
    end
  end
end
