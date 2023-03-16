# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::Abuse::NamespaceBans::DestroyService, feature_category: :insider_threat do
  describe '#execute' do
    let_it_be(:user_with_permissions) { create(:user) }
    let_it_be(:user_without_permissions) { create(:user) }
    let_it_be(:namespace) { create(:group) }

    let!(:namespace_ban) { create(:namespace_ban, namespace: namespace) }
    let(:current_user) { user_with_permissions }
    let(:service) { described_class.new(namespace_ban, current_user) }

    before_all do
      namespace.add_maintainer(user_without_permissions)
      namespace.add_owner(user_with_permissions)
    end

    describe '#execute' do
      shared_examples 'error response' do |message|
        it 'has an informative message' do
          expect(response).to be_error
          expect(response.message).to eq(message)
          expect(response.payload[:namespace_ban]).to eq(namespace_ban)
          expect { namespace_ban.reload }.not_to raise_error
        end
      end

      subject(:response) { service.execute }

      context 'when the current_user is anonymous' do
        let(:current_user) { nil }

        it_behaves_like 'error response', 'You have insufficient permissions to remove this Namespace Ban'
      end

      context 'when current_user does not have permission to create integrations' do
        let(:current_user) { user_without_permissions }

        it_behaves_like 'error response', 'You have insufficient permissions to remove this Namespace Ban'
      end

      context 'when an error occurs during removal' do
        before do
          allow(namespace_ban).to receive(:destroy).and_return(false)
          namespace_ban.errors.add(:base, 'Ban cannot be removed')
        end

        it_behaves_like 'error response', 'Ban cannot be removed'
      end

      it 'successfully deletes and returns the namespace_ban' do
        expect(response).to be_success
        expect(response.payload[:namespace_ban]).to eq(namespace_ban)
        expect { namespace_ban.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
