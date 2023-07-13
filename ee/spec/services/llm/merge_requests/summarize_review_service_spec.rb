# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::MergeRequests::SummarizeReviewService, :saas, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be_with_reload(:group) { create(:group_with_plan, :public, plan: :ultimate_plan) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }

  let_it_be(:merge_request_note) { create(:note, noteable: merge_request, project: project, author: user) }
  let!(:draft_note_by_current_user) { create(:draft_note, merge_request: merge_request, author: user) }
  let!(:draft_note_by_random_user) { create(:draft_note, merge_request: merge_request) }

  describe "#perform" do
    before do
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_licensed_features(summarize_my_mr_code_review: true, ai_features: true)

      group.add_developer(user)

      group.namespace_settings.update!(third_party_ai_features_enabled: true, experiment_features_enabled: true)
    end

    subject { described_class.new(user, merge_request, {}).execute }

    context "when testing validity" do
      shared_examples "returns an error" do
        it { is_expected.to be_error.and have_attributes(message: eq(described_class::INVALID_MESSAGE)) }
      end

      context "when resource is not a merge request" do
        subject { described_class.new(user, create(:issue), {}).execute }

        it_behaves_like "returns an error"
      end

      context "when :openai_experimentation is disabled" do
        before do
          stub_feature_flags(openai_experimentation: false)
        end

        it_behaves_like "returns an error"
      end

      context "when merge request has no associated draft notes" do
        before do
          allow(merge_request).to receive(:draft_notes).and_return(DraftNote.none)
        end

        it_behaves_like "returns an error"
      end
    end

    it "enqueues a new worker" do
      expect(Llm::CompletionWorker).to receive(:perform_async).with(
        user.id,
        merge_request.id,
        merge_request.class.name,
        :summarize_review,
        { request_id: an_instance_of(String) }
      )

      expect(subject).to be_success
    end
  end
end
