# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::Create::WorkspaceVariablesCreator, feature_category: :remote_development do
  include ResultMatchers

  include_context 'with remote development shared fixtures'

  let_it_be(:user) { create(:user) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:workspace) { create(:workspace, user: user, personal_access_token: personal_access_token) }
  let(:invalid_workspace_variables) do
    [
      {
        key: "does-not-matter",
        value: "does-not-matter",
        variable_type: 9999999,
        workspace_id: workspace.id
      }
    ]
  end

  let(:expected_workspace_variables_params) do
    variables = RemoteDevelopment::Workspaces::Create::WorkspaceVariables.variables(
      name: workspace.name,
      dns_zone: workspace.dns_zone,
      personal_access_token_value: personal_access_token.token,
      user_name: user.name,
      user_email: user.email,
      workspace_id: workspace.id
    )
    variables.each do |variable|
      variable[:workspace_id] = workspace.id
    end
  end

  let(:value) do
    {
      workspace: workspace,
      current_user: user,
      personal_access_token: personal_access_token
    }
  end

  subject(:result) do
    described_class.create(value) # rubocop:disable Rails/SaveBang
  end

  context 'when workspace variables create is successful' do
    it 'creates the workspace variables and returns ok result containing successful message with created variables' do
      expect { subject }.to change { workspace.workspace_variables.count }

      expect(result).to be_ok_result do |message|
        message => { workspace_variables_params: Array => workspace_variables_params }
        expect(workspace_variables_params).to eq(expected_workspace_variables_params)
      end
    end
  end

  context 'when workspace create fails' do
    before do
      allow(RemoteDevelopment::Workspaces::Create::WorkspaceVariables)
        .to receive(:variables)
              .and_return(invalid_workspace_variables)
    end

    it 'does not create the workspace and returns an error result containing a failed message with model errors' do
      expect { subject }.not_to change { workspace.workspace_variables.count }

      expect(result).to be_err_result do |message|
        expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceVariablesModelCreateFailed)
        message.context => { errors: ActiveModel::Errors => errors }
        expect(errors.full_messages).to match([/variable type/i])
      end
    end
  end
end
