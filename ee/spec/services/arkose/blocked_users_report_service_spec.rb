# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arkose::BlockedUsersReportService do
  let(:service) { described_class.new }
  subject { service.execute }

  let(:arkose_labs_public_api_key) { 'foo' }
  let(:arkose_labs_private_api_key) { 'bar' }

  let(:response) { instance_double(HTTParty::Response, success?: true, code: 200, parsed_response: {}) }

  before do
    stub_application_setting(arkose_labs_public_api_key: arkose_labs_public_api_key)
    stub_application_setting(arkose_labs_private_api_key: arkose_labs_private_api_key)
  end

  describe '#execute' do
    context 'when there are blocked users to report' do
      let(:arkose_body) do
        {
          publicKey: arkose_labs_public_api_key,
          privateKey: arkose_labs_private_api_key,
          sessions: ['22612c147bb418c8.2570749403']
        }.to_json
      end

      let(:user) { create(:user) }
      let(:blocked_at) { DateTime.now - 1.day }

      let!(:user_custom_attributes) do
        user.custom_attributes.create!(
          key: 'blocked_at',
          value: blocked_at, created_at: DateTime.now - 1.day,
          updated_at: DateTime.now - 1.day
        )

        user.custom_attributes.create!(
          key: 'arkose_session',
          value: '22612c147bb418c8.2570749403'
        )
      end

      let(:non_legit_url) { Arkose::BlockedUsersReportService::NON_LEGIT_URL }

      it 'sends the list of blocked users to Arkose' do
        allow(Gitlab::HTTP).to receive(:perform_request).with(
          Net::HTTP::Post,
          non_legit_url,
          body: arkose_body
        ).and_return(response)

        expect(subject).to be_truthy
      end
    end

    context 'when there are no blocked users to report' do
      it 'does not sends the list of blocked users to Arkose' do
        expect(Gitlab::HTTP).not_to receive(:perform_request)

        expect(subject).to be_truthy
      end
    end

    context 'when all blocked users does not have the arkose session' do
      let(:blocked_user_without_arkose_session) { create(:user) }
      let(:blocked_at) { DateTime.now - 1.day }
      let!(:user_custom_attributes) do
        blocked_user_without_arkose_session.custom_attributes.create!(
          key: 'blocked_at',
          value: blocked_at,
          created_at: DateTime.now - 1.day,
          updated_at: DateTime.now - 1.day
        )
      end

      it 'does not sends the list of blocked users to Arkose' do
        expect(UserCustomAttribute).to receive(:by_key).exactly(3).times.and_call_original
        expect(Gitlab::HTTP).not_to receive(:perform_request)

        expect(subject).to be_truthy
      end
    end

    context 'when Arkose api keys are not available' do
      before do
        stub_application_setting(arkose_labs_public_api_key: nil)
        stub_application_setting(arkose_labs_private_api_key: nil)
      end

      it 'does not sends the list of blocked users to Arkose' do
        expect(UserCustomAttribute).not_to receive(:by_user_id)

        expect(subject).to be_truthy
      end
    end
  end
end
