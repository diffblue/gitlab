# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupLinks::DestroyService, '#execute', feature_category: :subgroups do
  subject { described_class.new(shared_group, owner) }

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:shared_group) { create(:group, :private) }
  let_it_be(:owner) { create(:user) }

  before do
    group.add_developer(owner)
    shared_group.add_owner(owner)
  end

  context 'with a single link' do
    let!(:link) { create(:group_group_link, shared_group: shared_group, shared_with_group: group) }
    let(:audit_context) do
      {
        name: 'group_share_with_group_link_removed',
        stream_only: false,
        author: owner,
        scope: shared_group,
        target: group,
        message: "Removed #{group.name} from the group #{shared_group.name}"
      }
    end

    it 'sends an audit event' do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(audit_context)).once

      subject.execute(link)
    end
  end

  context 'with multiple links' do
    let_it_be(:another_group) { create(:group, :private) }
    let_it_be(:another_shared_group) { create(:group, :private) }

    let!(:links) do
      [
        create(:group_group_link, shared_group: shared_group, shared_with_group: group),
        create(:group_group_link, shared_group: shared_group, shared_with_group: another_group),
        create(:group_group_link, shared_group: another_shared_group, shared_with_group: group),
        create(:group_group_link, shared_group: another_shared_group, shared_with_group: another_group)
      ]
    end

    it 'sends multiple audit events' do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including({ name: 'group_share_with_group_link_removed' })
      ).exactly(links.size).times

      subject.execute(links)
    end
  end
end
