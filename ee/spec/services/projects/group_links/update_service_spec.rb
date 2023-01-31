# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinks::UpdateService do
  let_it_be(:user) { create :user }
  let_it_be(:group) { create :group }
  let_it_be(:project) { create :project }

  let!(:link) { create(:project_group_link, project: project, group: group, group_access: Gitlab::Access::DEVELOPER) }

  let(:expiry_date) { 1.month.from_now.to_date }
  let(:group_link_params) do
    { group_access: Gitlab::Access::GUEST,
      expires_at: expiry_date }
  end

  subject(:execute_update_service) { described_class.new(link, user).execute(group_link_params) }

  before do
    group.add_maintainer(user)
  end

  context 'audit events' do
    it 'sends the audit streaming event' do
      audit_context = {
        name: 'project_group_link_updated',
        author: user,
        scope: project,
        target: group,
        message: "Changed project group link profile group_access from Developer to Guest \
profile expires_at from nil to #{expiry_date}",
        additional_details: {
          change: {
            access_level: { from: 'Developer', to: 'Guest' },
            invite_expiry: { from: 'nil', to: expiry_date }
          }
        }
      }
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)

      execute_update_service
    end

    context 'when only expires_at is updated' do
      let(:group_link_params) do
        { expires_at: expiry_date }
      end

      it 'sends the audit streaming event' do
        audit_context = {
          name: 'project_group_link_updated',
          author: user,
          scope: project,
          target: group,
          message: "Changed project group link profile expires_at from nil to #{expiry_date}",
          additional_details: {
            change: {
              invite_expiry: { from: 'nil', to: expiry_date }
            }
          }
        }
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)

        execute_update_service
      end

      context 'when expires_at is already same' do
        let(:group_link_params) do
          { expires_at: expiry_date }
        end

        before do
          link.update!(expires_at: expiry_date)
        end

        it 'does not send audit streaming event' do
          expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

          execute_update_service
        end
      end
    end

    context 'when only access_level is updated' do
      let(:group_link_params) do
        { group_access: Gitlab::Access::GUEST }
      end

      it 'sends the audit streaming event' do
        audit_context = {
          name: 'project_group_link_updated',
          author: user,
          scope: project,
          target: group,
          message: "Changed project group link profile group_access from Developer to Guest",
          additional_details: {
            change: {
              access_level: { from: 'Developer', to: 'Guest' }
            }
          }
        }
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)

        execute_update_service
      end

      context 'when access_level is already same' do
        let(:group_link_params) do
          { group_access: Gitlab::Access::GUEST }
        end

        before do
          link.update!(group_access: Gitlab::Access::GUEST)
        end

        it 'does not send audit streaming event' do
          expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

          execute_update_service
        end
      end
    end
  end
end
