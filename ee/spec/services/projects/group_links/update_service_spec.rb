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

  subject { described_class.new(link, user).execute(group_link_params) }

  before do
    group.add_maintainer(user)
  end

  context 'audit events' do
    it 'sends the audit streaming event' do
      audit_context = {
        name: 'project_group_link_update',
        stream_only: true,
        author: user,
        scope: project,
        target: group,
        message: "Changed project group link profile group_access from Developer to Guest \
profile expires_at from nil to #{expiry_date}"
      }
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)

      subject
    end
  end
end
