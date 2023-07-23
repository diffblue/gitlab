# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'workspaces', feature_category: :remote_development do
  let_it_be(:group) { create(:group, :private) }
  let(:result) { execute['data'] }
  let_it_be(:user) { create(:user) }
  let_it_be(:workspace) { create(:workspace, user: user, updated_at: 2.days.ago) }

  let(:query) do
    %(
      query {
        workspace(id: "gid://gitlab/RemoteDevelopment::Workspace/#{workspace.id}") {
          id
          name
        }
      }
    )
  end

  subject(:execute) { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

  before do
    stub_licensed_features(remote_development: true)
  end

  describe 'workspace' do
    let(:current_user) { user }

    it 'finds the workspace' do
      expect(result["workspace"]["name"]).to eq(workspace.name)
    end

    context 'when not authorized' do
      let(:current_user) { create :user }

      it 'does not find the workspace' do
        expect(result["workspace"]).to be_nil
      end
    end
  end
end
