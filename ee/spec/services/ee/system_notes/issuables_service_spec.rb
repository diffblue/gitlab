# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::IssuablesService, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:author) { create(:user) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be_with_reload(:noteable) { create(:issue, project: project, health_status: 'on_track') }

  let(:service) { described_class.new(noteable: noteable, project: project, author: author) }

  describe '#change_health_status_note' do
    subject { service.change_health_status_note(noteable.health_status_before_last_save) }

    context 'when health_status changed' do
      before do
        noteable.update!(health_status: 'at_risk')
      end

      it_behaves_like 'a system note' do
        let(:action) { 'health_status' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq "changed health status to **at risk**"
      end
    end

    context 'when health_status removed' do
      before do
        noteable.update!(health_status: nil)
      end

      it_behaves_like 'a system note' do
        let(:action) { 'health_status' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'removed health status **on track**'
      end
    end

    describe 'events tracking', :snowplow do
      it 'tracks the issue event in usage ping' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_health_status_changed_action)
                                                                           .with(author: author, project: project)

        subject
      end

      it_behaves_like 'issue_edit snowplow tracking' do
        let(:property) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_HEALTH_STATUS_CHANGED }
        let(:user) { author }
      end
    end
  end

  describe '#change_progress_note' do
    let_it_be(:noteable) { create(:work_item, :objective, project: project) }
    let_it_be(:progress) { create(:progress, work_item: noteable) }

    subject { service.change_progress_note }

    it_behaves_like 'a system note' do
      let(:action) { 'progress' }
    end

    it 'sets the progress text' do
      expect(subject.note).to eq "changed progress to **#{progress&.progress}**"
    end
  end

  describe '#publish_issue_to_status_page' do
    let_it_be(:noteable) { create(:issue, project: project) }

    subject { service.publish_issue_to_status_page }

    it_behaves_like 'a system note' do
      let(:action) { 'published' }
    end

    it 'sets the note text' do
      expect(subject.note).to eq 'published this issue to the status page'
    end
  end

  describe '#cross_reference' do
    let(:mentioned_in) { create(:issue, project: project) }

    subject { service.cross_reference(mentioned_in) }

    context 'when noteable is an epic' do
      let(:noteable) { epic }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'cross_reference' }
      end

      it 'tracks epic cross reference event in usage ping' do
        expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_cross_referenced)
          .with(author: author, namespace: group)

        subject
      end
    end

    context 'when notable is not an epic' do
      it 'does not tracks epic cross reference event in usage ping' do
        expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).not_to receive(:track_epic_cross_referenced)

        subject
      end
    end

    describe '#relate_issuable' do
      let(:noteable) { epic }
      let(:target) { create(:epic) }

      it 'creates system notes when relating epics' do
        result = service.relate_issuable(target)

        expect(result.note).to eq("marked this epic as related to #{target.to_reference(target.group, full: true)}")
      end
    end
  end

  describe '#unrelate_issuable' do
    let(:noteable) { epic }
    let(:target) { create(:epic) }

    it 'creates system notes when epic gets unrelated' do
      result = service.unrelate_issuable(target)

      expect(result.note).to eq("removed the relation with #{target.to_reference(noteable.group)}")
    end
  end

  describe '#block_issuable' do
    let(:noteable_ref) { create(:issue) }

    subject { service.block_issuable(noteable_ref) }

    it_behaves_like 'a system note' do
      let(:action) { 'relate' }
    end

    it 'creates system note when issues gets marked as blocking' do
      expect(subject.note).to eq "marked this issue as blocking #{noteable_ref.to_reference(project)}"
    end
  end

  describe '#blocked_by_issuable' do
    let(:noteable_ref) { create(:issue) }

    subject { service.blocked_by_issuable(noteable_ref) }

    it_behaves_like 'a system note' do
      let(:action) { 'relate' }
    end

    it 'creates system note when issues gets marked as blocked by noteable' do
      expect(subject.note).to eq "marked this issue as blocked by #{noteable_ref.to_reference(project)}"
    end
  end
end
