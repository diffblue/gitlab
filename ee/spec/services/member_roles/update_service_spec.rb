# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberRoles::UpdateService, feature_category: :system_access do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:member_role) { create(:member_role, :guest, namespace: group, read_vulnerability: true) }

  describe '#execute' do
    let(:params) { { name: 'new name', read_vulnerability: false } }

    subject(:result) { described_class.new(group, user, params).execute(member_role) }

    before do
      stub_licensed_features(custom_roles: true)
    end

    context 'with unauthorized user' do
      before_all do
        group.add_maintainer(user)
      end

      it 'returns an error' do
        expect(result).to be_error
      end
    end

    context 'with authorized user' do
      before_all do
        group.add_owner(user)
      end

      context 'with valid params' do
        it 'is succesful' do
          expect(result).to be_success
        end

        it 'updates the provided (permitted) attribute' do
          expect { result }.to change { member_role.reload.name }.to('new name')
        end

        it 'does not update unpermitted attribute' do
          expect { result }.not_to change { member_role.reload.read_vulnerability }
        end
      end

      context 'when member role can not be updated' do
        before do
          error_messages = double

          allow(member_role).to receive(:save).and_return(false)
          allow(member_role).to receive(:errors).and_return(error_messages)
          allow(error_messages).to receive(:full_messages).and_return(['this is wrong'])
        end

        it 'is not succesful' do
          expect(result).to be_error
        end

        it 'includes the object errors' do
          expect(result.message).to eq(['this is wrong'])
        end
      end
    end
  end
end
