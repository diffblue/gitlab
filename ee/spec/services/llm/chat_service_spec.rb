# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::ChatService, :saas, feature_category: :shared do
  let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:stage_check_available) { true }

  let_it_be(:options) do
    {
      content: "Summarize issue"
    }
  end

  subject { described_class.new(user, issue, options) }

  before do
    stub_licensed_features(ai_chat: true)
    stub_feature_flags(gitlab_duo: user)
    project.add_guest(user)

    allow(Gitlab::Llm::StageCheck).to receive(:available?).with(group, :chat).and_return(stage_check_available)
  end

  describe '#perform' do
    it_behaves_like 'completion worker sync and async' do
      let(:resource) { issue }
      let(:action_name) { :chat }
      let(:content) { 'Summarize issue' }
    end

    context 'when gitlab_duo feature flag is disabled' do
      before do
        stub_feature_flags(gitlab_duo: false)
      end

      it 'returns an error' do
        expect(Llm::CompletionWorker).not_to receive(:perform_async)

        expect(subject.execute).to be_error
      end
    end

    context 'when ai_chat licensed feature is disabled' do
      before do
        stub_licensed_features(ai_chat: false)
      end

      it 'returns an error' do
        expect(Llm::CompletionWorker).not_to receive(:perform_async)

        expect(subject.execute).to be_error
      end
    end

    it 'returns an error if user is not a member of the project' do
      project.team.truncate

      expect(Llm::CompletionWorker).not_to receive(:perform_async)

      expect(subject.execute).to be_error
    end

    context 'when namespace is not allowed to send data' do
      let(:stage_check_available) { false }

      it 'returns an error if user is not a member of the project' do
        expect(Llm::CompletionWorker).not_to receive(:perform_async)
        expect(subject.execute).to be_error
      end
    end
  end
end
