# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupLinks::CreateService, '#execute', feature_category: :subgroups do
  subject { described_class.new(group, shared_with_group, user, opts) }

  let_it_be(:shared_with_group) { create(:group, :private) }
  let_it_be(:user) { create(:user) }

  let(:group) { create(:group, :private) }
  let(:opts) do
    {
      shared_group_access: Gitlab::Access::DEVELOPER,
      expires_at: nil
    }
  end

  let(:audit_context) do
    {
      name: 'group_share_with_group_link_created',
      stream_only: false,
      author: user,
      scope: group,
      target: shared_with_group,
      message: "Invited #{shared_with_group.name} to the group #{group.name}"
    }
  end

  before do
    shared_with_group.add_guest(user)
    group.add_owner(user)
  end

  it 'sends an audit event' do
    expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context).once

    subject.execute
  end
end
