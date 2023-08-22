# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::Create::PersonalAccessTokenCreator, feature_category: :remote_development do
  include ResultMatchers

  include_context 'with remote development shared fixtures'

  let_it_be(:user) { create(:user) }
  let(:workspace_name) { "workspace-example_agent_id-example_user_id-example_random_string" }
  let(:max_hours_before_termination) { 24 }
  let(:params) do
    {
      max_hours_before_termination: max_hours_before_termination
    }
  end

  let(:value) do
    {
      params: params,
      current_user: user,
      workspace_name: workspace_name
    }
  end

  subject(:result) do
    described_class.create(value) # rubocop:disable Rails/SaveBang
  end

  context 'when personal access token creation is successful' do
    it 'returns ok result containing successful message with created token' do
      expect { subject }.to change { user.personal_access_tokens.count }

      expect(result).to be_ok_result do |message|
        message => { personal_access_token: PersonalAccessToken => personal_access_token }
        expect(personal_access_token).to eq(user.personal_access_tokens.reload.last)
      end
    end
  end

  context 'when personal access token creation fails' do
    let(:max_hours_before_termination) { 999999999999 }

    it 'returns an error result containing a failed message with model errors' do
      expect { subject }.not_to change { user.personal_access_tokens.count }

      expect(result).to be_err_result do |message|
        expect(message).to be_a(RemoteDevelopment::Messages::PersonalAccessTokenModelCreateFailed)
        message.context => { errors: ActiveModel::Errors => errors }
        expect(errors.full_messages).to match([/expiration date/i])
      end
    end
  end
end
