# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::UpdateService, feature_category: :subgroups do
  let(:project) { create(:project, :public) }
  let(:group) { create(:group, :public) }
  let(:current_user) { create(:user) }
  let(:member_user) { create(:user) }
  let(:permission) { :update }
  let(:member) { source.members_and_requesters.find_by!(user_id: member_user.id) }
  let(:params) do
    { access_level: Gitlab::Access::MAINTAINER, expires_at: 2.days.from_now }
  end

  before do
    project.add_developer(member_user)
    group.add_developer(member_user)
  end

  shared_examples_for 'logs an audit event' do
    specify do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including(name: "member_updated")
      ).and_call_original

      expect do
        described_class.new(current_user, params).execute(member, permission: permission)
      end.to change { AuditEvent.count }.by(1)
    end
  end

  shared_examples_for 'does not log an audit event' do
    specify do
      expect do
        described_class.new(current_user, params).execute(member, permission: permission)
      end.not_to change { AuditEvent.count }
    end
  end

  context 'when current user can update the given member' do
    before do
      project.add_maintainer(current_user)
      group.add_owner(current_user)
    end

    it_behaves_like 'logs an audit event' do
      let(:source) { project }
    end

    it_behaves_like 'logs an audit event' do
      let(:source) { group }
    end

    context 'when the update is a noOp' do
      subject(:service) { described_class.new(current_user, params) }

      before do
        service.execute(member, permission: permission)
      end

      it_behaves_like 'does not log an audit event' do
        let(:source) { group }
      end

      it_behaves_like 'does not log an audit event' do
        let(:source) { project }
      end

      context 'when access_level remains the same and expires_at changes' do
        before do
          described_class.new(
            current_user,
            params.merge(expires_at: 24.days.from_now)
          ).execute(member, permission: permission)
        end

        it_behaves_like 'logs an audit event' do
          let(:source) { group }
        end
      end

      context 'when expires_at remains the same and access_level changes' do
        before do
          described_class.new(
            current_user,
            params.merge(access_level: Gitlab::Access::OWNER)
          ).execute(member, permission: permission)
        end

        it_behaves_like 'logs an audit event' do
          let(:source) { group }
        end
      end
    end
  end
end
