# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeployTokens::DestroyService do
  let_it_be(:entity) { create(:project) }
  let_it_be(:deploy_token) { create(:deploy_token, projects: [entity]) }
  let_it_be(:user) { create(:user) }
  let_it_be(:deploy_token_params) { { token_id: deploy_token.id } }

  describe '#execute' do
    subject { described_class.new(entity, user, deploy_token_params).execute }

    it "destroys a token record and it's associated DeployToken" do
      expect { subject }.to change { ProjectDeployToken.count }.by(-1)
                                                               .and change { DeployToken.count }.by(-1)
    end

    it "creates an audit event" do
      expect { subject }.to change { AuditEvent.count }.by(1)

      expected_message = <<~MESSAGE.squish
        Destroyed project deploy token with name: #{deploy_token.name}
        with token_id: #{deploy_token.id} with scopes: #{deploy_token.scopes}.
      MESSAGE

      expect(AuditEvent.last.details[:custom_message]).to eq(expected_message)
    end
  end
end
