# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth, :use_clean_rails_memory_store_caching do
  let_it_be(:project) { create(:project) }

  let(:auth_failure) { { actor: nil, project: nil, type: nil, authentication_abilities: nil } }
  let(:gl_auth) { described_class }

  context 'when personal access tokens are disabled' do
    before do
      stub_licensed_features(disable_personal_access_tokens: true)
      stub_application_setting(disable_personal_access_tokens: true)
    end

    it 'fails authentication when using personal access tokens' do
      personal_access_token = create(:personal_access_token, scopes: ['api'])

      expect(gl_auth.find_for_git_client('', personal_access_token.token, project: nil, ip: 'ip'))
        .to have_attributes(auth_failure)
    end

    it 'fails authentication when using impersonation tokens' do
      impersonation_token = create(:personal_access_token, :impersonation, scopes: ['api'])

      expect(gl_auth.find_for_git_client('', impersonation_token.token, project: nil, ip: 'ip'))
        .to have_attributes(auth_failure)
    end

    it 'fails authentication when using a resource access token' do
      project_bot_user = create(:user, :project_bot)
      access_token = create(:personal_access_token, user: project_bot_user)

      expect(gl_auth.find_for_git_client(project_bot_user.username, access_token.token, project: project, ip: 'ip'))
        .to have_attributes(auth_failure)
    end
  end
end
