# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ManualQuarterlyCoTermBannerHelper do
  describe '#manual_quarterly_co_term_banner' do
    subject(:manual_quarterly_co_term_banner) { helper.manual_quarterly_co_term_banner }

    let_it_be(:current_user) { create(:admin) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    context 'when current user is empty' do
      let(:current_user) { nil }

      it 'does not return a banner payload' do
        expect(manual_quarterly_co_term_banner).to eq(nil)
      end
    end

    context 'when current user cannot admin all resources' do
      it 'does not return a banner payload' do
        expect(manual_quarterly_co_term_banner).to eq(nil)
      end
    end

    context 'when current user can admin all resources' do
      before do
        allow(current_user).to receive(:can_admin_all_resources?).and_return(true)
      end

      it 'returns a banner payload' do
        expect(manual_quarterly_co_term_banner).to be_an_instance_of(Gitlab::ManualQuarterlyCoTermBanner)
      end
    end
  end
end
