# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ManualRenewalBannerHelper do
  describe '#manual_renewal_banner' do
    subject(:manual_renewal_banner) { helper.manual_renewal_banner }

    let_it_be(:current_user) { create(:admin) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    context 'when current user is empty' do
      let(:current_user) { nil }

      it 'does not return a banner payload' do
        expect(manual_renewal_banner).to eq(nil)
      end
    end

    context 'when current user cannot admin all resources' do
      it 'does not return a banner payload' do
        expect(manual_renewal_banner).to eq(nil)
      end
    end

    context 'when current user can admin all resources' do
      before do
        allow(current_user).to receive(:can_admin_all_resources?).and_return(true)

        allow_next_instance_of(Gitlab::ManualRenewalBanner) do |banner|
          allow(banner).to receive(:display?).and_return(display_banner)
        end
      end

      context 'when no banner instance is returned' do
        let(:display_banner) { false }

        it 'does not return a banner payload' do
          aggregate_failures do
            expect(manual_renewal_banner).to be_an_instance_of(Gitlab::ManualRenewalBanner)
            expect(manual_renewal_banner.subject).to eq(nil)
          end
        end
      end

      context 'when a banner instance is returned' do
        let(:display_banner) { true }

        context 'when current license is expired' do
          before do
            allow(License).to receive(:current).and_return(create(:license, expires_at: 1.month.ago.to_date))
          end

          it 'returns a banner payload' do
            aggregate_failures do
              expect(manual_renewal_banner).to be_an_instance_of(Gitlab::ManualRenewalBanner)
              expect(manual_renewal_banner.subject).to include('subscription expired')
              expect(manual_renewal_banner.display_error_version?).to eq(true)
            end
          end
        end

        context 'when current license is not expired' do
          it 'returns a banner payload' do
            aggregate_failures do
              expect(manual_renewal_banner).to be_an_instance_of(Gitlab::ManualRenewalBanner)
              expect(manual_renewal_banner.subject).to include('subscription expires')
              expect(manual_renewal_banner.display_error_version?).to eq(false)
            end
          end
        end
      end
    end
  end
end
