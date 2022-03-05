# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DeployTokensController do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:deploy_token) { create(:deploy_token, :group, groups: [group]) }
  let_it_be(:params) do
    { id: deploy_token.id, group_id: group }
  end

  before do
    group.add_owner(user)

    sign_in(user)
  end

  describe 'PUT /groups/:group_path_with_namespace/-/deploy_tokens/:id/revoke' do
    subject(:put_revoke) do
      put "/groups/#{group.full_path}/-/deploy_tokens/#{deploy_token.id}/revoke", params: params
    end

    it 'creates an audit event' do
      expect { put_revoke }.to change { AuditEvent.count }.by(1)

      expect(response).to redirect_to(group_settings_repository_path(group, anchor: 'js-deploy-tokens'))

      expected_message = <<~MESSAGE.squish
        Revoked group deploy token with name: #{deploy_token.name}
        with token_id: #{deploy_token.id} with scopes: #{deploy_token.scopes}.
      MESSAGE

      expect(AuditEvent.last.details[:custom_message]).to eq(expected_message)
    end
  end
end
