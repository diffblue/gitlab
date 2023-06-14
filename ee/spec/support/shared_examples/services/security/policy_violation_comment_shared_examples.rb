# frozen_string_literal: true

RSpec.shared_examples_for 'triggers policy bot comment' do |report_type, expected_violation|
  context 'when feature flag "security_policy_approval_notification" is enabled' do
    it 'enqueues Security::GeneratePolicyViolationCommentWorker' do
      expect(Security::GeneratePolicyViolationCommentWorker).to receive(:perform_async).with(
        merge_request.id,
        { 'report_type' => Security::ScanResultPolicies::PolicyViolationComment::REPORT_TYPES[report_type],
          'violated_policy' => expected_violation }
      )

      execute
    end
  end

  context 'when feature flag "security_policy_approval_notification" is disabled' do
    before do
      stub_feature_flags(security_policy_approval_notification: false)
    end

    it 'does not enqueue Security::GeneratePolicyViolationCommentWorker' do
      expect(Security::GeneratePolicyViolationCommentWorker).not_to receive(:perform_async)

      execute
    end
  end
end
