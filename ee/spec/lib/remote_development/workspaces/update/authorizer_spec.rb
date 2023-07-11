# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Update::Authorizer, feature_category: :remote_development do
  include ResultMatchers

  let(:workspace) { build_stubbed(:workspace) }
  let(:user) { build_stubbed(:user) }
  let(:user_can_update_workspace) { true }
  let(:params) { instance_double(Hash) }
  let(:value) { { workspace: workspace, current_user: user, params: params } }

  subject(:result) do
    described_class.authorize(value)
  end

  before do
    allow(user).to receive(:can?).with(:update_workspace, workspace).and_return(user_can_update_workspace)
  end

  context 'when user is authorized' do
    it 'returns an ok Result containing the original value which was passed' do
      expect(result).to eq(Result.ok(value))
    end
  end

  context 'when user is not authorized' do
    let(:user_can_update_workspace) { false }

    it 'returns an err Result containing an unauthorized message with an empty context' do
      expect(result).to be_err_result(RemoteDevelopment::Messages::Unauthorized.new)
    end
  end
end
