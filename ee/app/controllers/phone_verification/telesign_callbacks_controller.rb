# frozen_string_literal: true

# https://developer.telesign.com/enterprise/docs/transaction-callback-service
module PhoneVerification
  class TelesignCallbacksController < ApplicationController
    respond_to :json

    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token

    feature_category :instance_resiliency
    urgency :low

    def notify
      callback = ::Telesign::TransactionCallback.new(request, params)

      return not_found unless callback.valid?

      callback.log

      render json: {}
    end
  end
end
