# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NavHelper, feature_category: :navigation do
  describe '#show_super_sidebar?' do
    subject { helper.show_super_sidebar? }

    let(:user) { build(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      stub_feature_flags(super_sidebar_nav: true)
      user.update!(use_new_navigation: true)
      helper.instance_variable_set(:@nav, nav)
    end

    context 'when nav is supported' do
      %w[your_work project group].each do |context_nav|
        context "with #{context_nav}" do
          let(:nav) { context_nav }

          it 'returns true' do
            expect(subject).to be true
          end
        end
      end
    end

    context 'when nav is not set' do
      let(:nav) { nil }

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when nav is not supported' do
      let(:nav) { 'unsupported' }

      it 'returns true' do
        expect(subject).to be false
      end
    end
  end
end
