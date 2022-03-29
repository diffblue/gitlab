# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Quality::TestGroupCleanupProdWorker do
  let(:qa_user) { create(:user, username: 'test-user') }
  let!(:groups_to_remove) { create_list(:group, 3) }
  let!(:group_to_keep) { create(:group, :test_group) }
  let!(:non_test_group) { create(:group) }

  subject { described_class.new }

  describe "#perform" do
    before do
      stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)

      groups_to_remove.each do |group|
        group.add_owner(create(:user))
        create(:group_member, :developer, group: group, user: qa_user)
        create(:group_deletion_schedule, group: group, marked_for_deletion_on: 1.day.ago)
      end

      group_to_keep.add_owner(create(:user))
    end

    context 'when not in production environment' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
        stub_const("Quality::TestGroupCleanupProdWorker::QA_USER_IN_PRODUCTION", 'test-user')
      end

      it 'does not remove any groups' do
        expect { subject.perform }.to not_change(Group, :count)
      end
    end

    context 'when qa user does not exist' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
        stub_const("Quality::TestGroupCleanupProdWorker::QA_USER_IN_PRODUCTION", 'other-test-user')
      end

      it 'does not remove any groups' do
        expect { subject.perform }.to not_change(Group, :count)
      end
    end

    context 'with multiple groups to remove' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
        stub_const("Quality::TestGroupCleanupProdWorker::QA_USER_IN_PRODUCTION", 'test-user')
      end

      it 'successfully removes test groups' do
        expect { subject.perform }.to change(Group, :count).by(-3)
      end
    end
  end
end
