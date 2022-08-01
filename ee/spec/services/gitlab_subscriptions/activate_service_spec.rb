# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::ActivateService do
  subject(:execute_service) { described_class.new.execute(activation_code) }

  let!(:application_settings) do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  let_it_be(:license_key) { build(:gitlab_license, :cloud).export }

  let(:activation_code) { 'activation_code' }

  def stub_client_activate
    expect(Gitlab::SubscriptionPortal::Client).to receive(:activate)
      .with(activation_code)
      .and_return(customer_dot_response)
  end

  before do
    allow(Gitlab::CurrentSettings).to receive(:current_application_settings).and_return(application_settings)
  end

  context 'when CustomerDot returns success' do
    let(:customer_dot_response) { { success: true, license_key: license_key } }

    before do
      stub_client_activate
    end

    it 'persists license' do
      freeze_time do
        result = execute_service
        created_license = License.current

        expect(result).to eq({ success: true, license: created_license })

        expect(created_license).to have_attributes(
          data: license_key,
          cloud: true,
          last_synced_at: Time.current
        )
      end
    end

    context 'when the current license key does not match the one returned from activation' do
      it 'creates a new license' do
        previous_license = create(:license, cloud: true, last_synced_at: 3.days.ago)

        freeze_time do
          expect { execute_service }.to change(License.cloud, :count).by(1)

          current_license = License.current
          expect(current_license.id).not_to eq(previous_license.id)
          expect(current_license).to have_attributes(
            data: license_key,
            cloud: true,
            last_synced_at: Time.current
          )
        end
      end
    end

    context 'when the current license key matches the one returned from activation' do
      it 'reuses the current license and updates the last_synced_at' do
        create(:license, cloud: true, last_synced_at: 3.days.ago)
        current_license = create(:license, cloud: true, data: license_key, last_synced_at: 1.day.ago)

        freeze_time do
          expect { execute_service }.not_to change(License.cloud, :count)

          expect(License.current).to have_attributes(
            id: current_license.id,
            data: license_key,
            cloud: true,
            last_synced_at: Time.current
          )
        end
      end
    end

    context 'when persisting fails' do
      let(:license_key) { 'invalid key' }

      it 'returns error' do
        expect(execute_service).to match({ errors: [be_a_kind_of(String)], success: false })
      end
    end
  end

  context 'when CustomerDot returns failure' do
    let(:customer_dot_response) { { success: false, errors: ['foo'] } }

    it 'returns error' do
      stub_client_activate

      expect(execute_service).to eq(customer_dot_response)

      expect(License.current&.data).not_to eq(license_key)
    end
  end

  context 'when not self managed instance' do
    let(:customer_dot_response) { { success: false, errors: [described_class::ERROR_MESSAGES[:not_self_managed]] } }

    it 'returns error' do
      allow(Gitlab).to receive(:com?).and_return(true)
      expect(Gitlab::SubscriptionPortal::Client).not_to receive(:activate)

      expect(execute_service).to eq(customer_dot_response)
    end
  end

  context 'when error is raised' do
    it 'captures error' do
      expect(Gitlab::SubscriptionPortal::Client).to receive(:activate).and_raise('foo')

      expect(execute_service).to eq({ success: false, errors: ['foo'] })
    end
  end
end
