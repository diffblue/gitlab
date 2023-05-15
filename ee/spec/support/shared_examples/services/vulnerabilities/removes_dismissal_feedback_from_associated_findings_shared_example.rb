# frozen_string_literal: true

RSpec.shared_examples 'removes dismissal feedback from associated findings' do
  let(:finding) { create(:vulnerabilities_finding, vulnerability: vulnerability, project: vulnerability.project) }

  before do
    create(
      :vulnerability_feedback,
      :dismissal,
      project: finding.project,
      category: finding.report_type,
      finding_uuid: finding.uuid
    )
  end

  context 'when there is no error' do
    it 'removes dismissal feedback from associated findings' do
      expect { subject }.to change { Vulnerabilities::Feedback.count }.by(-1)
    end
  end

  context 'when there is an error' do
    before do
      allow_next_instance_of(VulnerabilityFeedback::DestroyService) do |destroy_service_object|
        allow(destroy_service_object).to receive(:execute).and_return(false)
      end
    end

    it 'does not remove any feedback' do
      expect { subject }.not_to change { Vulnerabilities::Feedback.count }
    end

    it 'responds with error' do
      expect(subject.errors.messages).to eq(
        base: ["failed to revert associated finding(id=#{finding.id}) to detected"])
    end
  end
end
