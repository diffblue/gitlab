# frozen_string_literal: true

module Arkose
  class RecordUserDataService
    attr_reader :response, :user

    def initialize(response:, user:)
      @response = response
      @user = user
    end

    def execute
      return ServiceResponse.error(message: 'user is required') unless user.present?
      return ServiceResponse.error(message: 'Invalid Arkose Labs token') if response.invalid_token?

      add_or_update_arkose_attributes

      ServiceResponse.success
    end

    private

    def add_or_update_arkose_attributes
      return if Gitlab::Database.read_only?

      UserCustomAttribute.upsert_custom_attributes(custom_attributes)
    end

    def custom_attributes
      custom_attributes = []
      custom_attributes.push({ key: 'arkose_session', value: response.session_id })
      custom_attributes.push({ key: 'arkose_device_id', value: response.device_id }) unless response.device_id.nil?
      custom_attributes.push({ key: UserCustomAttribute::ARKOSE_RISK_BAND, value: response.risk_band })
      custom_attributes.push({ key: 'arkose_global_score', value: response.global_score })
      custom_attributes.push({ key: 'arkose_custom_score', value: response.custom_score })

      custom_attributes.map! { |custom_attribute| custom_attribute.merge({ user_id: user.id }) }
      custom_attributes
    end
  end
end
