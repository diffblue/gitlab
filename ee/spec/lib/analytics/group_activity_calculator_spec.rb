# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::GroupActivityCalculator, :use_clean_rails_memory_store_caching do
  subject { described_class.new(group, current_user) }

  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:another_user) { create(:user) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: subgroup) }
  let_it_be(:secret_project) { create(:project, group: create(:group, parent: group)) }

  before do
    subgroup.add_developer(current_user)
    subgroup.add_developer(another_user)
    project.add_developer(current_user)
  end

  context 'with issues' do
    before_all do
      create(:issue, project: project)
      create(:issue, project: project, created_at: 40.days.ago)
    end

    it 'only returns the count of recent issues' do
      expect(subject.issues_count).to eq 1
    end

    context 'when user does not have access to some issues' do
      it 'does not include those issues' do
        create(:issue, project: secret_project)

        expect(subject.issues_count).to eq 1
      end
    end

    it 'caches value per user' do
      expect(subject.issues_count).to eq 1

      create(:issue, project: project)

      expect(subject.issues_count).to eq 1
      expect(described_class.new(group, another_user).issues_count).to eq 2
    end

    it 'limits count to RECENT_COUNT_LIMIT' do
      stub_const('Analytics::GroupActivityCalculator::RECENT_COUNT_LIMIT', 2)

      create(:issue, project: project)
      create(:issue, project: project)

      expect(subject.issues_count).to eq 2
    end
  end

  context 'with merge requests' do
    before_all do
      create(:merge_request,
             source_project: project,
             source_branch: "my-personal-branch-1")

      create(:merge_request,
             source_project: project,
             source_branch: "my-personal-branch-2",
             created_at: 40.days.ago)
    end

    it 'only returns the count of recent MRs' do
      expect(subject.merge_requests_count).to eq 1
    end

    context 'when user does not have access to some MRs' do
      it 'does not include those MRs' do
        create(:merge_request, source_project: secret_project)

        expect(subject.merge_requests_count).to eq 1
      end
    end

    it 'caches value per user' do
      expect(subject.merge_requests_count).to eq 1

      create(:merge_request,
             source_project: project,
             source_branch: "my-personal-branch-3")

      expect(subject.merge_requests_count).to eq 1
      expect(described_class.new(group, another_user).merge_requests_count).to eq 2
    end

    it 'limits count to RECENT_COUNT_LIMIT' do
      stub_const('Analytics::GroupActivityCalculator::RECENT_COUNT_LIMIT', 2)

      create(:merge_request,
             source_project: project,
             source_branch: "my-personal-branch-3")
      create(:merge_request,
             source_project: project,
             source_branch: "my-personal-branch-4")

      expect(subject.merge_requests_count).to eq 2
    end
  end

  context 'with members' do
    it 'returns the count of recently added members' do
      expect(subject.new_members_count).to eq 2 # current_user + another_user
    end

    context 'when there is a member who was not added recently' do
      before do
        travel_to(40.days.ago) do
          subgroup.add_developer create(:user, created_at: 2.days.ago)
        end
      end

      it 'returns the count of recently added members' do
        expect(subject.new_members_count).to eq 2 # current_user + another_user
      end
    end

    context 'when user does not have access to some members' do
      it 'does not include those members' do
        secret_project.add_developer create(:user)

        expect(subject.new_members_count).to eq 2
      end
    end

    it 'caches value per user' do
      expect(subject.new_members_count).to eq 2

      subgroup.add_developer create(:user)

      expect(subject.new_members_count).to eq 2
      expect(described_class.new(group, another_user).new_members_count).to eq 3
    end

    it 'limits count to RECENT_COUNT_LIMIT' do
      stub_const('Analytics::GroupActivityCalculator::RECENT_COUNT_LIMIT', 2)

      subgroup.add_developer create(:user)
      subgroup.add_developer create(:user)

      expect(subject.new_members_count).to eq 2
    end
  end
end
