# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::ResetRegistrationTokenService, '#execute' do
  subject { described_class.new(scope, current_user).execute }

  let_it_be(:user) { build(:user) }
  let_it_be(:admin_user) { create_default(:user, :admin) }

  shared_examples 'a registration token reset operation' do
    context 'without user' do
      let(:current_user) { nil }

      it 'does not reset registration token and returns false' do
        expect(scope).not_to receive(:reset_runners_token!)

        is_expected.to eq(false)
      end
    end

    context 'with unauthorized user' do
      let(:current_user) { user }

      it 'does not reset registration token and returns false' do
        expect(scope).not_to receive(:reset_runners_token!)

        is_expected.to eq(false)
      end
    end

    context 'with admin user', :enable_admin_mode do
      let(:current_user) { admin_user }

      it 'resets registration token and returns value unchanged' do
        expect(scope).to receive(:reset_runners_token!).once do
          expect(scope).to receive(:runners_token).once.and_return('runners_token return value')
        end

        is_expected.to eq('runners_token return value')
      end
    end
  end

  context 'with instance scope' do
    let_it_be(:scope) { create(:application_setting) }

    before do
      allow(ApplicationSetting).to receive(:current).and_return(scope)
      allow(ApplicationSetting).to receive(:current_without_cache).and_return(scope)
    end

    context 'without user' do
      let(:current_user) { nil }

      it 'does not reset registration token and returns false' do
        expect(scope).not_to receive(:reset_runners_registration_token!)

        is_expected.to eq(false)
      end
    end

    context 'with unauthorized user' do
      let(:current_user) { user }

      it 'calls assign_to on runner and returns value unchanged' do
        expect(scope).not_to receive(:reset_runners_registration_token!)

        is_expected.to eq(false)
      end
    end

    context 'with admin user', :enable_admin_mode do
      let(:current_user) { admin_user }

      it 'resets registration token and returns value unchanged' do
        expect(scope).to receive(:reset_runners_registration_token!).once do
          expect(scope).to receive(:runners_registration_token).once.and_return('runners_registration_token return value')
        end

        is_expected.to eq('runners_registration_token return value')
      end
    end
  end

  context 'with group scope' do
    let_it_be(:scope) { create(:group) }

    it_behaves_like 'a registration token reset operation'
  end

  context 'with project scope' do
    let_it_be(:scope) { create(:project) }

    it_behaves_like 'a registration token reset operation'
  end
end
