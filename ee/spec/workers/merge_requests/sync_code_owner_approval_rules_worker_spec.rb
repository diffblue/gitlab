# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeRequests::SyncCodeOwnerApprovalRulesWorker, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { create(:merge_request) }

  subject { described_class.new }

  describe "#perform" do
    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [merge_request.id] }
    end

    context "when merge request is not found" do
      it "returns without attempting to sync code owner rules" do
        expect(MergeRequests::SyncCodeOwnerApprovalRules).not_to receive(:new)

        subject.perform(non_existing_record_id)
      end
    end

    context "when merge request is found" do
      it "attempts to sync code owner rules" do
        expect_next_instance_of(::MergeRequests::SyncCodeOwnerApprovalRules) do |instance|
          expect(instance).to receive(:execute)
        end

        subject.perform(merge_request.id)
      end
    end
  end
end
