# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Create::Authorizer, feature_category: :remote_development do
  include ResultMatchers

  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }
  let(:params) { { project: project } }
  let(:value) { { current_user: user, params: params } }

  subject(:result) do
    described_class.authorize(value)
  end

  before do
    allow(user).to receive(:can?).with(:create_workspace, project).and_return(user_can_create_workspace)
  end

  context 'when user is authorized' do
    let(:user_can_create_workspace) { true }

    it 'returns an ok Result containing the original value which was passed' do
      expect(result).to eq(Result.ok(value))
    end
  end

  context 'when user is not authorized' do
    let(:user_can_create_workspace) { false }

    it 'returns an err Result containing an unauthorized message with an empty context' do
      expect(result).to be_err_result(RemoteDevelopment::Messages::Unauthorized.new)
    end
  end
end
