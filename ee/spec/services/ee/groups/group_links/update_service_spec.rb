# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupLinks::UpdateService, '#execute', feature_category: :subgroups do
  subject { described_class.new(link, user).execute(group_link_params) }

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:shared_group) { create(:group, :private) }
  let_it_be(:user) { create(:user) }

  let(:link) { create(:group_group_link, shared_group: shared_group, shared_with_group: group) }
  let(:expiry_date) { 1.month.from_now.to_date }
  let(:group_link_params) do
    { group_access: Gitlab::Access::GUEST,
      expires_at: expiry_date }
  end

  let(:audit_context) do
    {
      name: 'group_share_with_group_link_updated',
      stream_only: false,
      author: user,
      scope: shared_group,
      target: group,
      message: "Updated #{group.name}'s " \
               "access params for the group #{shared_group.name}",
      additional_details: {
        changes: [
          { change: :group_access, from: 'Developer', to: 'Guest' },
          { change: :expires_at, from: '', to: expiry_date.to_s }
        ]
      }
    }
  end

  before do
    group.add_developer(user)
  end

  it 'sends an audit event' do
    expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(audit_context)).once

    subject
  end
end
