# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::GenerateTestFileService, feature_category: :code_review_workflow do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let(:options) { {} }

  subject { described_class.new(user, merge_request, options) }

  describe '#execute' do
    before do
      stub_licensed_features(generate_test_file: true)
      group.namespace_settings.update!(third_party_ai_features_enabled: true)
      allow(Llm::CompletionWorker).to receive(:perform_async)
    end

    context 'when the user is permitted to view the merge request' do
      before do
        project.add_maintainer(user)
      end

      it 'schedules a job' do
        expect(subject.execute).to be_success

        expect(Llm::CompletionWorker).to have_received(:perform_async).with(
          user.id,
          merge_request.id,
          'MergeRequest',
          :generate_test_file,
          options
        )
      end
    end

    context 'when the user is not permitted to view the merge request' do
      it 'returns an error' do
        project.team.truncate

        expect(subject.execute).to be_error

        expect(Llm::CompletionWorker).not_to have_received(:perform_async)
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(generate_test_file_flag: false)
      end

      it 'returns an error' do
        expect(subject.execute).to be_error

        expect(Llm::CompletionWorker).not_to have_received(:perform_async)
      end
    end
  end
end
