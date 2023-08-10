# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::GenerateTestFileService, :saas, feature_category: :code_review_workflow do
  let_it_be_with_refind(:group) { create(:group_with_plan, :public, plan: :ultimate_plan) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:project) { create(:project, :public, group: group) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:options) { {} }

  subject { described_class.new(user, merge_request, options) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_licensed_features(generate_test_file: true, ai_features: true)
  end

  describe '#execute' do
    before do
      group.namespace_settings.update!(
        third_party_ai_features_enabled: true,
        experiment_features_enabled: true)
      allow(Llm::CompletionWorker).to receive(:perform_async)
    end

    context 'when member of the group' do
      let(:resource) { merge_request }
      let(:action_name) { :generate_test_file }
      let(:content) { 'Generate test file' }

      before do
        group.add_developer(user)
      end

      it_behaves_like 'service not emitting message for user prompt'
      it_behaves_like 'completion worker sync and async'
      it_behaves_like 'llm service does not cache user request'

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

    context 'when the user is not permitted to view the merge request' do
      it 'returns an error' do
        expect(subject.execute).to be_error

        expect(Llm::CompletionWorker).not_to have_received(:perform_async)
      end
    end
  end

  describe '#valid?' do
    using RSpec::Parameterized::TableSyntax

    where(:experiment_features_enabled, :third_party_ai_features_enabled, :result) do
      true   | true  | true
      false  | true  | false
      true   | false | false
      false  | false | false
    end

    with_them do
      before do
        group.add_developer(user)
        project.root_ancestor.namespace_settings.update!(
          third_party_ai_features_enabled: third_party_ai_features_enabled,
          experiment_features_enabled: experiment_features_enabled)
      end

      subject { described_class.new(user, merge_request, options) }

      it { expect(subject.valid?).to eq(result) }
    end
  end
end
