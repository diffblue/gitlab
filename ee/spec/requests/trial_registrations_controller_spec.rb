# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialRegistrationsController do
  let(:com) { true }

  before do
    allow(Gitlab).to receive(:com?).and_return(com)
    stub_feature_flags(arkose_labs_signup_challenge: false)
  end

  describe 'POST new' do
    let(:user_params) do
      build_stubbed(:user)
        .slice(:first_name, :last_name, :email, :username, :password)
    end

    context 'when email_opted_in does not exist in params' do
      it 'sets user email_opted_in to false' do
        post trial_registrations_path, params: { user: user_params }

        expect(response).to have_gitlab_http_status(:found)
        expect(User.last.email_opted_in).to be_nil
      end
    end

    context 'when email_opted_in is true in params' do
      it 'sets user email_opted_in to true' do
        post trial_registrations_path, params: {
          user: user_params.merge(email_opted_in: true)
        }

        expect(response).to have_gitlab_http_status(:found)
        expect(User.last.email_opted_in).to be true
      end
    end
  end
end
