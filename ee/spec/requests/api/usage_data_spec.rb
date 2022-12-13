# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UsageData, feature_category: :service_ping do
  let_it_be(:user) { create(:user) }

  describe 'POST /usage_data/increment_counter' do
    let(:endpoint) { '/usage_data/increment_counter' }

    context 'with authentication' do
      before do
        stub_feature_flags(usage_data_api: true)
        stub_application_setting(usage_ping_enabled: true)
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(true)
      end

      context 'with correct params' do
        using RSpec::Parameterized::TableSyntax

        where(:prefix, :event) do
          'users' | 'clicking_license_testing_visiting_external_website'
          'users' | 'visiting_testing_license_compliance_full_report'
        end

        before do
          stub_application_setting(usage_ping_enabled: true)
          stub_feature_flags(usage_data_api: true)
          allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(true)
        end

        with_them do
          it 'returns status :ok' do
            expect(::Gitlab::UsageDataCounters::BaseCounter).to receive(:count).with(event)
            post api(endpoint, user), params: { event: "#{prefix}_#{event}" }
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end
  end
end
