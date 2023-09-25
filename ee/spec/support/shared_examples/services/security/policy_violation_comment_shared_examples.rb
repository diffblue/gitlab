# frozen_string_literal: true

RSpec.shared_examples_for 'triggers policy bot comment' do |report_type, expected_violation,
  requires_approval: expected_violation|
  it 'enqueues Security::GeneratePolicyViolationCommentWorker' do
    expect(Security::GeneratePolicyViolationCommentWorker).to receive(:perform_async).with(
      merge_request.id,
      { 'report_type' => Security::ScanResultPolicies::PolicyViolationComment::REPORT_TYPES[report_type],
        'violated_policy' => expected_violation,
        'requires_approval' => requires_approval }
    )

    execute
  end
end
