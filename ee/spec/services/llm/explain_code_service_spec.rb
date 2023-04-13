# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::ExplainCodeService, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let_it_be(:options) do
    {
      messages: [
        { role: 'user', content: 'user content' },
        { role: 'system', content: 'system content' }
      ]
    }
  end

  subject { described_class.new(user, project, options) }

  before do
    stub_licensed_features(explain_code: true)
    project.add_guest(user)
  end

  describe '#perform' do
    it 'schedules a job' do
      expect(Llm::CompletionWorker).to receive(:perform_async).with(
        user.id, project.id, 'Project', :explain_code, options
      )

      expect(subject.execute).to be_success
    end

    context 'when explain_code_snippet feature flag is disabled' do
      before do
        stub_feature_flags(explain_code_snippet: false)
      end

      it 'returns an error' do
        expect(Llm::CompletionWorker).not_to receive(:perform_async)

        expect(subject.execute).to be_error
      end
    end

    context 'when explain_code licensed feature is disabled' do
      before do
        stub_licensed_features(explain_code: false)
      end

      it 'returns an error' do
        expect(Llm::CompletionWorker).not_to receive(:perform_async)

        expect(subject.execute).to be_error
      end
    end

    context 'when a project is not public' do
      let_it_be(:project) { create(:project) }

      it 'returns an error' do
        expect(Llm::CompletionWorker).not_to receive(:perform_async)

        expect(subject.execute).to be_error
      end
    end

    it 'returns an error when messages are too big' do
      stub_const("#{described_class}::INPUT_CONTENT_LIMIT", 4)

      expect(Llm::CompletionWorker).not_to receive(:perform_async)

      expect(subject.execute).to be_error.and have_attributes(message: eq('The messages are too big'))
    end

    it 'returns an error if user is not a member of the project' do
      project.team.truncate

      expect(Llm::CompletionWorker).not_to receive(:perform_async)

      expect(subject.execute).to be_error
    end
  end
end
