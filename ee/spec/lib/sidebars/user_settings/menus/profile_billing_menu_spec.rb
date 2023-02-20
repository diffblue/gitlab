# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::ProfileBillingMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/profile/billing',
    title: _('Billing'),
    icon: 'credit-card',
    active_routes: { controller: :billings }

  describe '#render?' do
    subject { described_class.new(context) }

    let_it_be(:user) { build(:user) }

    context 'when namespace check is required' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
      end

      context 'when user is logged in' do
        let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

        it 'does not render' do
          expect(subject.render?).to be true
        end
      end

      context 'when user is not logged in' do
        let(:context) { Sidebars::Context.new(current_user: nil, container: nil) }

        subject { described_class.new(context) }

        it 'does not render' do
          expect(subject.render?).to be false
        end
      end
    end

    context 'when namespace check is not required' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(false)
      end

      context 'when user is logged in' do
        let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

        it 'renders' do
          expect(subject.render?).to be false
        end
      end

      context 'when user is not logged in' do
        let(:context) { Sidebars::Context.new(current_user: nil, container: nil) }

        subject { described_class.new(context) }

        it 'does not render' do
          expect(subject.render?).to be false
        end
      end
    end
  end
end
