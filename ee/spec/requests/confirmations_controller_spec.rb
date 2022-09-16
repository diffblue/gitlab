# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConfirmationsController do
  describe '#create' do
    let_it_be(:user) { create(:user) }

    subject do
      post user_confirmation_path(user: { email: user.email })
      response
    end

    context 'when identity verification is turned off' do
      before do
        stub_feature_flags(identity_verification: false)
      end

      it { is_expected.to redirect_to(dashboard_projects_path) }
    end

    context 'when identity verification is turned on' do
      before do
        stub_feature_flags(identity_verification: true)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end
end
