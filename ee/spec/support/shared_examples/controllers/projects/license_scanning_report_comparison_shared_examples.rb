# frozen_string_literal: true

RSpec.shared_examples 'license scanning report comparison' do |with_report_trait|
  context 'when the report is being parsed' do
    let(:comparison_status) { { status: :parsing } }

    before do
      allow(::Gitlab::PollingInterval).to receive(:set_header)
    end

    it 'returns 204 HTTP status' do
      subject

      expect(::Gitlab::PollingInterval).to have_received(:set_header)
      expect(response).to have_gitlab_http_status(:no_content)
    end
  end

  context 'when comparison is being processed' do
    let(:comparison_status) { { status: :parsing } }

    it 'sends polling interval' do
      expect(::Gitlab::PollingInterval).to receive(:set_header)

      subject
    end

    it 'returns 204 HTTP status' do
      subject

      expect(response).to have_gitlab_http_status(:no_content)
    end
  end

  context 'when comparison is done' do
    it 'does not send polling interval' do
      expect(::Gitlab::PollingInterval).not_to receive(:set_header)

      subject
    end

    it 'returns 200 HTTP status' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(expected_response)
    end
  end

  context 'when user created corrupted test reports' do
    let(:comparison_status) { { status: :error, status_reason: 'Failed to parse license scanning reports' } }

    it 'does not send polling interval' do
      expect(::Gitlab::PollingInterval).not_to receive(:set_header)

      subject
    end

    it 'returns 400 HTTP status' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response).to eq({ 'status_reason' => 'Failed to parse license scanning reports' })
    end
  end

  context "when a user is authorized to read the licenses" do
    let_it_be(:project) { create(:project, :repository, :private) }
    let_it_be(:merge_request) { create(:ee_merge_request, with_report_trait, source_project: project, author: author) }

    let(:viewer) { create(:user) }

    before do
      project.add_reporter(viewer)
    end

    it 'returns 200 HTTP status' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  context "when license_scanning feature is disabled" do
    before do
      stub_licensed_features(license_scanning: false)
    end

    it 'returns 404 status' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
