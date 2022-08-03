# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::IssuablesService do
  let_it_be(:group)    { create(:group) }
  let_it_be(:project)  { create(:project, :repository, group: group) }
  let_it_be(:author)   { create(:user) }

  let(:noteable) { create(:issue, project: project) }
  let(:issue)    { noteable }
  let(:epic)     { create(:epic, group: group) }

  let(:service) { described_class.new(noteable: noteable, project: project, author: author) }

  describe '#change_health_status_note' do
    subject { service.change_health_status_note }

    context 'when health_status changed' do
      let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum', health_status: 'at_risk') }

      it_behaves_like 'a system note' do
        let(:action) { 'health_status' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq "changed health status to **at risk**"
      end
    end

    context 'when health_status removed' do
      let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum', health_status: nil) }

      it_behaves_like 'a system note' do
        let(:action) { 'health_status' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'removed the health status'
      end
    end

    describe 'events tracking', :snowplow do
      it 'tracks the issue event in usage ping' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_health_status_changed_action)
                                                                           .with(author: author, project: project)

        subject
      end

      it_behaves_like 'Snowplow event tracking' do
        let(:category) { 'issues_edit' }
        let(:action) { 'g_project_management_issue_health_status_changed' }
        let(:namespace) { project.namespace }
        let(:user) { author }
        let(:feature_flag_name) { :route_hll_to_snowplow_phase2 }
      end
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
end
