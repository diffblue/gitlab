# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeToRefService, feature_category: :source_code_management do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, :simple) }
  let(:project) { merge_request.project }
  let(:service) { described_class.new(project: project, current_user: user, params: params) }
  let(:params) { { commit_message: 'Awesome message' } }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    it 'does not check the repository size limit' do
      expect(project.repository_size_checker).not_to receive(:above_size_limit?)

      result = service.execute(merge_request)

      expect(result[:status]).to eq(:success)
    end

    context 'when no commit message is explicitly given and push rule is set' do
      before do
        create(:push_rule, :commit_message, project: project)
      end

      let(:service) { described_class.new(project: project, current_user: user) }

      it 'uses the default commit message' do
        result = service.execute(merge_request)

        expect(result[:status]).to eq(:success)
        expect(project.commit(result[:commit_id]).message).to eq(merge_request.default_merge_commit_message)
      end
    end
  end

  it_behaves_like 'merge validation hooks', persisted: false
end
