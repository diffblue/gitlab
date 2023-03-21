# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TwoFactor::DestroyService, feature_category: :system_access do
  let_it_be(:current_user) { create(:user, :two_factor) }
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, :two_factor, provisioned_by_group_id: group.id) }

  subject(:disable_2fa_with_group) { described_class.new(current_user, user: user, group: group).execute }

  shared_examples_for 'throws unauthorized error' do
    it 'returns error' do
      expect(disable_2fa_with_group).to eq(
        {
          status: :error,
          message: 'You are not authorized to perform this action'
        }
      )
    end
  end

  context "when current user is a group owner" do
    before do
      group.add_owner(current_user)
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(admin_audit_log: false, audit_events: false, extended_audit_events: false)
      end

      it 'does not track audit event' do
        expect { disable_2fa_with_group }.not_to change { AuditEvent.count }
      end
    end

    context "when licensed" do
      before do
        stub_licensed_features(admin_audit_log: true, audit_events: true, extended_audit_events: true)
      end

      it 'creates an audit event', :aggregate_failures do
        expect { disable_2fa_with_group }.to change(AuditEvent, :count).by(1)
                                            .and change { user.reload.two_factor_enabled? }.from(true).to(false)

        expect(AuditEvent.last).to have_attributes(
          author: current_user,
          entity_id: user.id,
          target_id: user.id,
          target_type: current_user.class.name,
          target_details: user.name,
          details: include(custom_message: 'Disabled two-factor authentication')
        )
      end

      context "when user is not provisioned by current group" do
        let(:new_group) { create(:group) }
        let(:user) { create(:user, :two_factor, provisioned_by_group_id: new_group.id) }

        it_behaves_like 'throws unauthorized error'
      end

      context "when group is non root" do
        let(:parent) { build(:group) }

        before do
          group.parent = parent
          parent.add_owner(create(:user))
        end

        it_behaves_like 'throws unauthorized error'
      end

      context "when user is not provisioned by group" do
        let(:user) { create(:user, :two_factor) }

        it_behaves_like 'throws unauthorized error'
      end
    end
  end

  context "when user is not a group owner" do
    it_behaves_like 'throws unauthorized error'

    context "when group is nil" do
      let(:group) { nil }

      it_behaves_like 'throws unauthorized error'
    end
  end

  context "when user passed is nil" do
    let(:user) { nil }

    it_behaves_like 'throws unauthorized error'
  end

  context 'when disabling two-factor authentication fails' do
    before do
      allow_next_instance_of(Users::UpdateService) do |instance|
        allow(instance).to receive(:execute)
              .and_return({ status: :error })
      end
    end

    it 'does not create an audit event' do
      expect { subject }.not_to change(AuditEvent, :count)
    end
  end
end
