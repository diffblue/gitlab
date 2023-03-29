# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issue, feature_category: :team_planning do
  include ExternalAuthorizationServiceHelpers

  using RSpec::Parameterized::TableSyntax

  describe 'associations' do
    subject { build(:issue) }

    it { is_expected.to belong_to(:iteration) }

    it { is_expected.to have_many(:resource_weight_events) }
    it { is_expected.to have_many(:resource_iteration_events) }
    it { is_expected.to have_one(:issuable_sla) }
    it { is_expected.to have_many(:metric_images) }
    it { is_expected.to have_many(:pending_escalations) }

    it { is_expected.to have_one(:requirement) }
    it { is_expected.to have_many(:test_reports) }
    it { is_expected.to have_many(:issuable_resource_links) }
  end

  describe 'modules' do
    subject { build(:issue) }

    it { is_expected.to include_module(EE::WeightEventable) }
  end

  context 'scopes' do
    describe 'health status' do
      let_it_be(:on_track) { create(:issue, health_status: :on_track) }
      let_it_be(:needs_attention) { create(:issue, health_status: :needs_attention) }
      let_it_be(:at_risk) { create(:issue, health_status: :at_risk) }
      let_it_be(:without_health_status) { create(:issue, health_status: nil) }

      describe '.with_health_status' do
        before_all do
          create(:issue, health_status: :needs_attention)
          create(:issue, health_status: nil)
        end

        it 'returns the filtered by health issues' do
          expect(described_class.with_health_status(:on_track)).to match_array([on_track])
        end

        context 'when using multiple health filter qualifications' do
          it 'returns the filtered by health issues' do
            expect(described_class.with_health_status([:at_risk, :on_track])).to match_array([on_track, at_risk])
          end
        end
      end

      describe '.with_any_health_status' do
        it 'only returns the issues with a health_status' do
          expect(described_class.with_any_health_status).to match_array([on_track, needs_attention, at_risk])
        end
      end

      describe '.with_no_health_status' do
        it 'only returns issues with no health status' do
          expect(described_class.with_no_health_status).to eq([without_health_status])
        end
      end

      describe '.without_health_status' do
        it 'returns the filtered by health issues' do
          expect(described_class.without_health_status(:on_track)).to contain_exactly(needs_attention, at_risk, without_health_status)
        end

        context 'when using multiple health filter qualifications' do
          it 'returns the filtered by health issues' do
            expect(described_class.without_health_status([:needs_attention, :on_track])).to contain_exactly(at_risk, without_health_status)
          end
        end
      end

      describe '.order_health_status_asc' do
        it 'returns healthy issues first' do
          expect(described_class.order_health_status_asc).to eq([on_track, needs_attention, at_risk, without_health_status])
        end
      end

      describe '.order_health_status_desc' do
        it 'returns non-healthy issues first' do
          expect(described_class.order_health_status_desc).to eq([at_risk, needs_attention, on_track, without_health_status])
        end
      end
    end

    describe '.for_requirement_iids' do
      let_it_be(:project) { create(:project) }
      let_it_be(:requirement1) { create(:work_item, :requirement, project: project).requirement }
      let_it_be(:requirement2) { create(:work_item, :requirement, project: project).requirement }
      let_it_be(:requirement3) { create(:work_item, :requirement, project: project).requirement }
      let_it_be(:requirement4) { create(:work_item, :requirement, project: project).requirement }

      context 'when issue is of type requirement' do
        let(:iids) { [requirement1.iid, requirement3.iid, requirement4.iid] }

        it 'filters requirement issues by associated requirements iids' do
          issue4 = requirement4.requirement_issue
          issue4.assign_attributes(
            issue_type: WorkItems::Type.base_types[:issue],
            work_item_type: WorkItems::Type.default_by_type(:issue)
          )
          # there should be no way to update a requirement to issue type, doing this to test the scope
          issue4.save!(validate: false)

          requirement_issues = Issue.for_requirement_iids(iids)

          expect(requirement_issues).to match_array([requirement1.requirement_issue, requirement3.requirement_issue])
        end

        it 'uses work_item_type_id to filter requirements' do
          expect { Issue.for_requirement_iids(iids).to_a }.to make_queries_matching(
            /"work_item_type"\."base_type" = #{WorkItems::Type.base_types[:requirement]}/
          )
        end

        context 'when issue_type_uses_work_item_types_table feature flag is disabled' do
          before do
            stub_feature_flags(issue_type_uses_work_item_types_table: false)
          end

          it 'uses the issue_type column to filter requirements' do
            expect { Issue.for_requirement_iids(iids).to_a }.to make_queries_matching(
              /"issues"\."issue_type" = #{WorkItems::Type.base_types[:requirement]}/
            )
          end
        end
      end
    end

    describe '.on_status_page' do
      let_it_be(:status_page_setting) { create(:status_page_setting, :enabled) }
      let_it_be(:project) { status_page_setting.project }
      let_it_be(:published_issue) { create(:issue, :published, project: project) }
      let_it_be(:confidential_issue) { create(:issue, :published, :confidential, project: project) }
      let_it_be(:nonpublished_issue) { create(:issue, project: project) }

      it { expect(Issue.on_status_page.count).to eq(1) }
      it { expect(Issue.on_status_page.first).to eq(published_issue) }

      context 'with status page disabled' do
        before do
          status_page_setting.update!(enabled: false)
        end

        it { expect(Issue.on_status_page.count).to eq(0) }
      end
    end

    describe '.with_feature' do
      let_it_be(:project) { create(:project) }
      let_it_be(:issue) { create(:issue, project: project) }
      let_it_be(:incident) { create(:incident, project: project) }
      let_it_be(:test_case) { create(:quality_test_case, project: project) }

      it 'gives issues that support the given feature', :aggregate_failures do
        expect(described_class.with_feature('epics'))
          .to contain_exactly(issue)

        expect(described_class.with_feature('sla'))
          .to contain_exactly(incident)
      end

      it 'returns an empty collection when given an unknown feature' do
        expect(described_class.with_feature('something-unknown'))
          .to be_empty
      end
    end

    context 'epics' do
      let_it_be(:epic1) { create(:epic) }
      let_it_be(:epic2) { create(:epic) }
      let_it_be(:epic_issue1) { create(:epic_issue, epic: epic1, relative_position: 2) }
      let_it_be(:epic_issue2) { create(:epic_issue, epic: epic2, relative_position: 1) }
      let_it_be(:issue_no_epic) { create(:issue) }

      before do
        stub_licensed_features(epics: true)
      end

      describe '.no_epic' do
        it 'returns only issues without an epic assigned' do
          expect(described_class.count).to eq 3
          expect(described_class.no_epic).to eq [issue_no_epic]
        end
      end

      describe '.any_epic' do
        it 'returns only issues with an epic assigned' do
          expect(described_class.count).to eq 3
          expect(described_class.any_epic).to contain_exactly(epic_issue1.issue, epic_issue2.issue)
        end
      end

      describe '.in_epics' do
        it 'returns only issues in selected epics' do
          expect(described_class.count).to eq 3
          expect(described_class.in_epics([epic1])).to eq [epic_issue1.issue]
        end
      end

      describe '.not_in_epics' do
        it 'returns only issues not in selected epics' do
          expect(described_class.count).to eq 3
          expect(described_class.not_in_epics([epic1])).to match_array([epic_issue2.issue, issue_no_epic])
        end
      end

      describe '.distinct_epic_ids' do
        it 'returns distinct epic ids' do
          expect(described_class.distinct_epic_ids.map(&:epic_id)).to match_array([epic1.id, epic2.id])
        end

        context 'when issues are grouped by labels' do
          let_it_be(:label_link1) { create(:label_link, target: epic_issue1.issue) }
          let_it_be(:label_link2) { create(:label_link, target: epic_issue1.issue) }

          it 'respects query grouping and returns distinct epic ids' do
            ids = described_class.with_label(
              [label_link1.label.title, label_link2.label.title]
            ).distinct_epic_ids.map(&:epic_id)
            expect(ids).to eq([epic1.id])
          end
        end
      end

      describe '.sorted_by_epic_position' do
        it 'sorts by epic relative position' do
          expect(described_class.sorted_by_epic_position.ids).to eq([epic_issue2.issue_id, epic_issue1.issue_id])
        end
      end
    end

    context 'iterations' do
      let_it_be(:iteration1) { create(:iteration, :with_title) }
      let_it_be(:iteration2) { create(:iteration) }
      let_it_be(:iteration1_issue) { create(:issue, iteration: iteration1) }
      let_it_be(:iteration2_issue) { create(:issue, iteration: iteration2) }
      let_it_be(:issue_no_iteration) { create(:issue) }

      before do
        stub_licensed_features(iterations: true)
      end

      describe '.no_iteration' do
        it 'returns only issues without an iteration assigned' do
          expect(described_class.count).to eq 3
          expect(described_class.no_iteration).to eq [issue_no_iteration]
        end
      end

      describe '.any_iteration' do
        it 'returns only issues with an iteration assigned' do
          expect(described_class.count).to eq 3
          expect(described_class.any_iteration).to contain_exactly(iteration1_issue, iteration2_issue)
        end
      end

      describe '.in_iterations' do
        it 'returns only issues in selected iterations' do
          expect(described_class.count).to eq 3
          expect(described_class.in_iterations([iteration1])).to eq [iteration1_issue]
        end
      end

      describe '.not_in_iterations' do
        it 'returns issues not in selected iterations' do
          expect(described_class.count).to eq 3
          expect(described_class.not_in_iterations([iteration1])).to contain_exactly(iteration2_issue, issue_no_iteration)
        end
      end

      describe '.with_iteration_title' do
        it 'returns only issues with iterations that match the title' do
          expect(described_class.with_iteration_title(iteration1.title)).to eq [iteration1_issue]
        end
      end

      describe '.without_iteration_title' do
        it 'returns only issues without iterations or have iterations that do not match the title' do
          expect(described_class.without_iteration_title(iteration1.title)).to contain_exactly(issue_no_iteration, iteration2_issue)
        end
      end
    end

    context 'status page published' do
      let_it_be(:not_published) { create(:issue) }
      let_it_be(:published)     { create(:issue, :published) }

      describe '.order_status_page_published_first' do
        subject { described_class.order_status_page_published_first }

        it { is_expected.to eq([published, not_published]) }
      end

      describe '.order_status_page_published_last' do
        subject { described_class.order_status_page_published_last }

        it { is_expected.to eq([not_published, published]) }
      end
    end

    context 'sla due at' do
      let_it_be(:project) { create(:project) }
      let_it_be(:sla_due_first) { create(:issue, project: project) }
      let_it_be(:sla_due_last)  { create(:issue, project: project) }
      let_it_be(:no_sla) { create(:issue, project: project) }

      before_all do
        create(:issuable_sla, :exceeded, issue: sla_due_first)
        create(:issuable_sla, issue: sla_due_last)
      end

      describe '.order_sla_due_at_asc' do
        subject { described_class.order_sla_due_at_asc }

        it { is_expected.to eq([sla_due_first, sla_due_last, no_sla]) }
      end

      describe '.order_sla_due_at_desc' do
        subject { described_class.order_sla_due_at_desc }

        it { is_expected.to eq([sla_due_last, sla_due_first, no_sla]) }
      end
    end
  end

  describe 'validations' do
    describe 'weight' do
      subject { build(:issue) }

      it 'is not valid when negative number' do
        subject.weight = -1

        expect(subject).not_to be_valid
        expect(subject.errors[:weight]).not_to be_empty
      end

      it 'is valid when non-negative' do
        subject.weight = 0

        expect(subject).to be_valid

        subject.weight = 1

        expect(subject).to be_valid
      end
    end

    describe 'confidential' do
      let_it_be(:epic) { create(:epic, :confidential) }

      context 'when assigning an epic to a new issue' do
        let(:issue) { build(:issue, confidential: confidential) }

        context 'when an issue is not confidential' do
          let(:confidential) { false }

          it 'is not valid' do
            issue.epic = epic

            expect(issue).not_to be_valid
            expect(issue.errors.messages[:base]).to include(/This issue cannot be assigned to a confidential epic because it is public./)
          end
        end

        context 'when an issue is confidential' do
          let(:confidential) { true }

          it 'is valid' do
            issue.epic = epic

            expect(issue).to be_valid
          end
        end
      end

      context 'when updating an existing issue' do
        let(:confidential) { true }
        let(:issue) { create(:issue, confidential: confidential) }

        context 'when an issue is assigned to the confidential epic' do
          before do
            issue.update!(epic: epic)
          end

          context 'when changing issue to public' do
            it 'is not valid' do
              issue.confidential = false

              expect(issue).not_to be_valid
              expect(issue.errors.messages[:base]).to include(/This issue cannot be made public because it belongs to a confidential epic./)
            end
          end
        end

        context 'when assigining a confidential issue' do
          it 'is valid' do
            issue.epic = epic

            expect(issue).to be_valid
          end
        end

        context 'when assigining a public issue' do
          let(:confidential) { false }

          it 'is not valid' do
            issue.epic = epic

            expect(issue).not_to be_valid
            expect(issue.errors.messages[:base]).to include(/This issue cannot be assigned to a confidential epic because it is public./)
          end
        end
      end
    end

    context 'when associated to a requirement object' do
      context 'when requirement belongs to another project' do
        it 'issue is invalid' do
          issue = create(:work_item, :requirement)

          issue.project = create(:project)

          expect(issue).not_to be_valid
          expect(issue.errors[:project_id]).to include(/must belong to same project of its requirement object/)
        end
      end
    end
  end

  describe 'relations' do
    it { is_expected.to have_many(:vulnerability_links).class_name('Vulnerabilities::IssueLink').inverse_of(:issue) }
    it { is_expected.to have_many(:related_vulnerabilities).through(:vulnerability_links).source(:vulnerability) }
    it { is_expected.to belong_to(:promoted_to_epic).class_name('Epic') }
    it { is_expected.to have_many(:resource_weight_events) }
    it { is_expected.to have_one(:status_page_published_incident) }
  end

  it_behaves_like 'an editable mentionable with EE-specific mentions' do
    subject { create(:issue, project: create(:project, :repository)) }

    let(:backref_text) { "issue #{subject.to_reference}" }
    let(:set_mentionable_text) { ->(txt) { subject.description = txt } }
  end

  describe '#allows_multiple_assignees?' do
    it 'does not allow multiple assignees without license' do
      stub_licensed_features(multiple_issue_assignees: false)

      issue = build(:issue)

      expect(issue.allows_multiple_assignees?).to be_falsey
    end

    it 'does not allow multiple assignees without license' do
      stub_licensed_features(multiple_issue_assignees: true)

      issue = build(:issue)

      expect(issue.allows_multiple_assignees?).to be_truthy
    end
  end

  describe '.simple_sorts' do
    it 'includes weight with other base keys' do
      expect(Issue.simple_sorts.keys).to match_array(
        %w(closest_future_date closest_future_date_asc created_asc
           created_at_asc created_at_desc created_date created_desc due_date
           due_date_asc due_date_desc id_asc id_desc relative_position
           relative_position_asc title_asc title_desc updated_asc updated_at_asc
           updated_at_desc updated_desc weight weight_asc weight_desc))
    end
  end

  describe '#sort' do
    let(:project) { create(:project) }

    context "by weight" do
      let!(:issue)  { create(:issue, project: project) }
      let!(:issue2) { create(:issue, weight: 1, project: project) }
      let!(:issue3) { create(:issue, weight: 2, project: project) }
      let!(:issue4) { create(:issue, weight: 3, project: project) }

      it "sorts desc" do
        issues = project.issues.sort_by_attribute('weight_desc')
        expect(issues).to eq([issue4, issue3, issue2, issue])
      end

      it "sorts asc" do
        issues = project.issues.sort_by_attribute('weight_asc')
        expect(issues).to eq([issue2, issue3, issue4, issue])
      end
    end

    context 'when weight is the same' do
      subject { project.issues.sort_by_attribute(sorting_param) }

      let!(:issue)  { create(:issue, project: project) }
      let!(:issue2) { create(:issue, weight: 1, project: project) }
      let!(:issue3) { create(:issue, weight: 1, project: project) }
      let!(:issue4) { create(:issue, weight: 1, project: project) }

      context 'sorting by asc' do
        let(:sorting_param) { 'weight_asc' }

        it 'arranges issues with the same weight by their ids' do
          is_expected.to eq([issue4, issue3, issue2, issue])
        end
      end

      context 'sorting by desc' do
        let(:sorting_param) { 'weight_desc' }

        it 'arranges issues with the same weight by their ids' do
          is_expected.to eq([issue4, issue3, issue2, issue])
        end
      end
    end

    context 'by blocking issues' do
      let_it_be(:issue_1) { create(:issue, blocking_issues_count: 3) }
      let_it_be(:issue_2) { create(:issue, blocking_issues_count: 1) }

      it 'orders by ascending blocking issues count', :aggregate_failures do
        results = described_class.sort_by_attribute('blocking_issues_asc')

        expect(results.first).to eq(issue_2)
        expect(results.second).to eq(issue_1)
      end

      it 'orders by descending blocking issues count', :aggregate_failures do
        results = described_class.sort_by_attribute('blocking_issues_desc')

        expect(results.first).to eq(issue_1)
        expect(results.second).to eq(issue_2)
      end
    end
  end

  describe '#weight' do
    where(:license_value, :database_value, :expected) do
      true  | 5   | 5
      true  | nil | nil
      false | 5   | nil
      false | nil | nil
    end

    with_them do
      let(:issue) { build(:issue, weight: database_value) }

      subject { issue.weight }

      before do
        stub_licensed_features(issue_weights: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#promoted?' do
    let(:issue) { create(:issue) }

    subject { issue.promoted? }

    context 'issue not promoted' do
      it { is_expected.to be_falsey }
    end

    context 'issue promoted' do
      let(:promoted_to_epic) { create(:epic) }
      let(:issue) { create(:issue, promoted_to_epic: promoted_to_epic) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#reopen' do
    let(:promoted_to_epic) { create(:epic) }
    let(:issue) { create(:issue, :closed, promoted_to_epic: promoted_to_epic) }

    it 'clears promoted_to_epic_id for promoted issues' do
      expect { issue.reopen }.to change { issue.promoted_to_epic_id }.from(promoted_to_epic.id).to(nil)
    end
  end

  context 'ES related specs', :elastic do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    context 'when updating an Issue' do
      let(:project) { create(:project, :public) }
      let(:issue) { create(:issue, project: project, confidential: true) }
      let!(:note) { create(:note, noteable: issue, project: project) }
      let!(:system_note) { create(:note, :system, noteable: issue, project: project) }

      context 'when changing the confidential value' do
        it 'updates issue notes excluding system notes' do
          expect_any_instance_of(Note).to receive(:maintain_elasticsearch_update) do |instance|
            expect(instance.id).to eq(note.id)
          end

          issue.update!(confidential: false)
        end
      end

      context 'when changing the author' do
        it 'updates issue notes excluding system notes' do
          expect_any_instance_of(Note).to receive(:maintain_elasticsearch_update) do |instance|
            expect(instance.id).to eq(note.id)
          end

          issue.update!(author: create(:user))
        end
      end

      context 'when changing the title' do
        it 'does not update issue notes' do
          expect_any_instance_of(Note).not_to receive(:maintain_elasticsearch_update)
          issue.update!(title: 'the new title')
        end
      end

      context 'when changing upvotes' do
        it 'calls maintain_elasticsearch_update' do
          expect(issue).to receive(:maintain_elasticsearch_update).twice

          award_emoji = create(:award_emoji, :upvote, awardable: issue)

          award_emoji.destroy!
        end
      end
    end
  end

  describe 'relative positioning with group boards' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:board) { create(:board, group: group) }
    let_it_be(:project) { create(:project, group: subgroup) }
    let_it_be(:project1) { create(:project, group: group) }
    let_it_be_with_reload(:issue) { create(:issue, project: project) }
    let_it_be_with_reload(:issue1) { create(:issue, project: project1, relative_position: issue.relative_position + RelativePositioning::IDEAL_DISTANCE) }

    let(:new_issue) { build(:issue, project: project1, relative_position: nil) }

    describe '.relative_positioning_query_base' do
      it 'includes cross project issues in the same group' do
        siblings = Issue.relative_positioning_query_base(issue)

        expect(siblings).to include(issue1)
      end
    end

    describe '#move_before' do
      it 'moves issue before' do
        [issue1, issue].each(&:move_to_end)

        issue.move_before(issue1)

        expect(issue.relative_position).to be < issue1.relative_position
      end
    end

    describe '#move_after' do
      it 'moves issue after' do
        [issue, issue1].each(&:move_to_end)

        issue.move_after(issue1)

        expect(issue.relative_position).to be > issue1.relative_position
      end
    end

    describe '#move_to_end' do
      it 'moves issue to the end' do
        new_issue.move_to_end

        expect(new_issue.relative_position).to be > issue1.relative_position
      end
    end

    describe '#move_between' do
      it 'positions issue between two other' do
        new_issue.move_between(issue, issue1)

        expect(new_issue.relative_position).to be > issue.relative_position
        expect(new_issue.relative_position).to be < issue1.relative_position
      end

      it 'positions issue between on top' do
        new_issue.move_between(nil, issue)

        expect(new_issue.relative_position).to be < issue.relative_position
      end

      it 'positions issue between to end' do
        new_issue.move_between(issue1, nil)

        expect(new_issue.relative_position).to be > issue1.relative_position
      end

      it 'positions issues even when after and before positions are the same' do
        issue1.update! relative_position: issue.relative_position

        new_issue.move_between(issue, issue1)
        [issue, issue1].each(&:reset)

        expect(new_issue.relative_position)
          .to be_between(issue.relative_position, issue1.relative_position).exclusive
      end

      it 'positions issues between other two if distance is 1' do
        issue1.update! relative_position: issue.relative_position + 1

        new_issue.move_between(issue, issue1)
        [issue, issue1].each(&:reset)

        expect(new_issue.relative_position)
          .to be_between(issue.relative_position, issue1.relative_position).exclusive
      end

      it 'positions issue in the middle of other two if distance is big enough' do
        issue.update! relative_position: 6000
        issue1.update! relative_position: 10000

        new_issue.move_between(issue, issue1)

        expect(new_issue.relative_position)
          .to be_between(issue.relative_position, issue1.relative_position).exclusive
      end

      it 'positions issue closer to the middle if we are at the very top' do
        new_issue.move_between(nil, issue)

        expect(new_issue.relative_position).to eq(issue.relative_position - RelativePositioning::IDEAL_DISTANCE)
      end

      it 'positions issue closer to the middle if we are at the very bottom' do
        new_issue.move_between(issue1, nil)

        expect(new_issue.relative_position).to eq(issue1.relative_position + RelativePositioning::IDEAL_DISTANCE)
      end

      it 'positions issue in the middle of other two if distance is not big enough' do
        issue.update! relative_position: 100
        issue1.update! relative_position: 400

        new_issue.move_between(issue, issue1)

        expect(new_issue.relative_position).to eq(250)
      end

      it 'positions issue in the middle of other two is there is no place' do
        issue.update! relative_position: 100
        issue1.update! relative_position: 101

        new_issue.move_between(issue, issue1)
        [issue, issue1].each(&:reset)

        expect(new_issue.relative_position)
          .to be_between(issue.relative_position, issue1.relative_position).exclusive
      end

      it 'uses rebalancing if there is no place' do
        issue.update! relative_position: 100
        issue1.update! relative_position: 101
        issue2 = create(:issue, relative_position: 102, project: project)
        new_issue.update! relative_position: 103

        new_issue.move_between(issue1, issue2)
        new_issue.save!
        [issue, issue1, issue2].each(&:reset)

        expect(new_issue.relative_position)
          .to be_between(issue1.relative_position, issue2.relative_position).exclusive

        expect([issue, issue1, issue2, new_issue].map(&:relative_position).uniq).to have_attributes(size: 4)
      end

      it 'positions issue right if we pass non-sequential parameters' do
        issue.update! relative_position: 99
        issue1.update! relative_position: 101
        issue2 = create(:issue, relative_position: 102, project: project)
        new_issue.update! relative_position: 103

        new_issue.move_between(issue, issue2)
        new_issue.save!

        expect(new_issue.relative_position).to be(100)
      end
    end
  end

  context 'when an external authentication service' do
    before do
      enable_external_authorization_service_check
    end

    describe '#visible_to_user?' do
      it 'does not check the external webservice for auditors' do
        issue = build(:issue)
        user = build(:auditor)

        expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

        issue.visible_to_user?(user)
      end
    end
  end

  describe "#issue_link_type" do
    let(:issue) { build(:issue) }

    it 'returns nil for a regular issue' do
      expect(issue.issue_link_type).to be_nil
    end

    where(:id, :issue_link_source_id, :issue_link_type_value, :expected) do
      1 | 1   | 0 | 'relates_to'
      1 | 1   | 1 | 'blocks'
      1 | 2   | 2 | 'relates_to'
      1 | 2   | 1 | 'is_blocked_by'
    end

    with_them do
      let(:issue) { build(:issue) }
      subject { issue.issue_link_type }

      before do
        allow(issue).to receive(:id).and_return(id)
        allow(issue).to receive(:issue_link_source_id).and_return(issue_link_source_id)
        allow(issue).to receive(:issue_link_type_value).and_return(issue_link_type_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe "#blocked_by_issues" do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:blocking_issue) { create(:issue, project: project) }
    let_it_be(:other_project_blocking_issue) { create(:issue) }
    let_it_be(:blocked_by_issue) { create(:issue, project: project) }
    let_it_be(:confidential_blocked_by_issue) { create(:issue, :confidential, project: project) }
    let_it_be(:related_issue) { create(:issue, project: project) }
    let_it_be(:closed_blocking_issue) { create(:issue, project: project, state: :closed) }

    before_all do
      create(:issue_link, source: blocking_issue, target: issue, link_type: IssueLink::TYPE_BLOCKS)
      create(:issue_link, source: other_project_blocking_issue, target: issue, link_type: IssueLink::TYPE_BLOCKS)
      create(:issue_link, source: blocked_by_issue, target: issue, link_type: IssueLink::TYPE_BLOCKS)
      create(:issue_link, source: confidential_blocked_by_issue, target: issue, link_type: IssueLink::TYPE_BLOCKS)
      create(:issue_link, source: issue, target: related_issue, link_type: IssueLink::TYPE_RELATES_TO)
      create(:issue_link, source: closed_blocking_issue, target: issue, link_type: IssueLink::TYPE_BLOCKS)
    end

    context 'when user can read issues' do
      it 'returns blocked issues' do
        project.add_developer(user)
        other_project_blocking_issue.project.add_developer(user)

        expect(issue.blocked_by_issues_for(user)).to match_array([blocking_issue, blocked_by_issue, other_project_blocking_issue, confidential_blocked_by_issue])
      end
    end

    context 'when user cannot read issues' do
      it 'returns empty array' do
        expect(issue.blocked_by_issues_for(user)).to be_empty
      end
    end

    context 'when user can read some issues' do
      it 'returns issues that user can read' do
        guest = create(:user)
        project.add_guest(guest)

        expect(issue.blocked_by_issues_for(guest)).to match_array([blocking_issue, blocked_by_issue])
      end
    end
  end

  it_behaves_like 'having health status'

  describe '#can_assign_epic?' do
    let(:user)    { create(:user) }
    let(:group)   { create(:group) }
    let(:project) { create(:project, group: group) }
    let(:issue)   { create(:issue, project: project) }

    subject { issue.can_assign_epic?(user) }

    context 'when epics feature is available' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when a user is not a project member' do
        it 'returns false' do
          expect(subject).to be_falsey
        end
      end

      context 'when a user is a project member' do
        before do
          project.add_reporter(user)
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'when epics feature is not available' do
      it 'returns false' do
        group.add_developer(user)

        expect(subject).to be_falsey
      end
    end

    describe '#update_blocking_issues_count' do
      it 'updates blocking issues count' do
        issue = create(:issue, project: project)
        blocked_issue_1 = create(:issue, project: project)
        blocked_issue_2 = create(:issue, project: project)
        blocked_issue_3 = create(:issue, project: project)
        create(:issue_link, source: issue, target: blocked_issue_1, link_type: IssueLink::TYPE_BLOCKS)
        create(:issue_link, source: issue, target: blocked_issue_2, link_type: IssueLink::TYPE_BLOCKS)
        create(:issue_link, source: issue, target: blocked_issue_3, link_type: IssueLink::TYPE_BLOCKS)
        # Set to 0 for proper testing, this is being set by IssueLink callbacks.
        issue.update!(blocking_issues_count: 0)

        expect { issue.update_blocking_issues_count! }
          .to change { issue.blocking_issues_count }.from(0).to(3)
      end
    end
  end

  context 'when changing state of blocking issues' do
    let_it_be(:project) { create(:project) }
    let_it_be(:blocking_issue1) { create(:issue, project: project) }
    let_it_be(:blocking_issue2) { create(:issue, project: project) }
    let_it_be(:blocked_issue) { create(:issue, project: project) }
    let_it_be(:blocked_by_blocked_issue) { create(:issue, project: project) }

    before_all do
      create(:issue_link, source: blocking_issue1, target: blocked_issue, link_type: IssueLink::TYPE_BLOCKS)
      create(:issue_link, source: blocking_issue2, target: blocked_issue, link_type: IssueLink::TYPE_BLOCKS)
      create(:issue_link, source: blocked_issue, target: blocked_by_blocked_issue, link_type: IssueLink::TYPE_BLOCKS)
    end

    before do
      blocked_issue.update!(blocking_issues_count: 0)
    end

    context 'when blocked issue is closed' do
      it 'updates blocking and blocked issues cache' do
        blocked_issue.close

        expect(blocking_issue1.reload.blocking_issues_count).to eq(0)
        expect(blocking_issue2.reload.blocking_issues_count).to eq(0)
        expect(blocked_issue.reload.blocking_issues_count).to eq(1)
      end
    end

    context 'when blocked issue is reopened' do
      before do
        blocked_issue.close
        blocked_issue.update!(blocking_issues_count: 0)
        blocking_issue1.update!(blocking_issues_count: 0)
        blocking_issue2.update!(blocking_issues_count: 0)
      end

      it 'updates blocking and blocked issues cache' do
        blocked_issue.reopen

        expect(blocking_issue1.reload.blocking_issues_count).to eq(1)
        expect(blocking_issue2.reload.blocking_issues_count).to eq(1)
        expect(blocked_issue.reload.blocking_issues_count).to eq(1)
      end
    end
  end

  describe '#can_be_promoted_to_epic?' do
    before do
      stub_licensed_features(epics: true)
    end

    let_it_be(:user) { create(:user) }

    let(:group) { nil }

    subject { issue.can_be_promoted_to_epic?(user, group) }

    context 'when project on the issue does not have a parent group' do
      let(:project) { create(:project) }
      let(:issue) { create(:issue, project: project) }

      before do
        project.add_developer(user)
      end

      it { is_expected.to be_falsey }
    end

    context 'when project on the issue is in a subgroup' do
      let(:parent_group) { create(:group) }
      let(:group) { create(:group, parent: parent_group) }
      let(:project) { create(:project, group: group) }
      let(:issue) { create(:issue, project: project) }

      before do
        group.add_developer(user)
        project.add_developer(user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when project has a parent group' do
      let_it_be(:group)   { create(:group) }
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:issue) { create(:issue, project: project) }

      context 'when a user is not a project member' do
        it { is_expected.to be_falsey }
      end

      context 'when a user is a project member' do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_falsey }
      end

      context 'when a user is a group member' do
        before do
          group.add_developer(user)
        end

        it { is_expected.to be_truthy }

        context 'when issue is an incident' do
          before do
            issue.update!(issue_type: :incident, work_item_type: WorkItems::Type.default_by_type(:incident))
          end

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#supports_iterations?' do
    let(:group) { build_stubbed(:group) }
    let(:project_with_group) { build_stubbed(:project, group: group) }

    where(:issuable_type, :project, :supports_iterations) do
      [
        [:issue, :project_with_group, true],
        [:incident, :project_with_group, false]
      ]
    end

    with_them do
      let(:issue) { build_stubbed(issuable_type, project: send(project)) }

      subject { issue.supports_iterations? }

      it { is_expected.to eq(supports_iterations) }
    end
  end

  describe '#issue_type_supports?' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:test_case) { create(:quality_test_case) }
    let_it_be(:incident) { create(:incident) }

    it do
      expect(issue.issue_type_supports?(:epics)).to be(true)
      expect(test_case.issue_type_supports?(:epics)).to be(false)
      expect(incident.issue_type_supports?(:epics)).to be(false)
    end
  end

  describe '#sla_available?' do
    let_it_be(:project) { create(:project) }
    let_it_be_with_refind(:issue) { create(:incident, project: project) }

    subject { issue.sla_available? }

    where(:incident_type, :license_available, :sla_available) do
      false | true  | false
      true  | false | false
      true  | true  | true
    end

    with_them do
      before do
        stub_licensed_features(incident_sla: license_available)
        issue_type = incident_type ? 'incident' : 'issue'
        issue.update!(issue_type: issue_type, work_item_type: WorkItems::Type.default_by_type(issue_type))
      end

      it 'returns the expected value' do
        expect(subject).to eq(sla_available)
      end
    end
  end

  describe '#supports_time_tracking?' do
    let_it_be(:project) { create(:project) }
    let_it_be_with_refind(:issue) { create(:incident, project: project) }

    where(:issue_type, :supports_time_tracking) do
      :requirement | false
      :test_case | false
    end

    with_them do
      before do
        issue.assign_attributes(issue_type: issue_type, work_item_type: WorkItems::Type.default_by_type(issue_type))
        issue.save!(validate: false)
      end

      it do
        expect(issue.supports_time_tracking?).to eq(supports_time_tracking)
      end
    end
  end

  describe '#supports_move_and_clone?' do
    let_it_be(:project) { create(:project) }
    let_it_be_with_refind(:issue) { create(:incident, project: project) }

    where(:issue_type, :supports_move_and_clone) do
      :requirement | false
      :test_case | true
    end

    with_them do
      before do
        issue.assign_attributes(issue_type: issue_type, work_item_type: WorkItems::Type.default_by_type(issue_type))
        issue.save!(validate: false)
      end

      it do
        expect(issue.supports_move_and_clone?).to eq(supports_move_and_clone)
      end
    end
  end

  describe '#related_feature_flags' do
    let_it_be(:user) { create(:user) }

    let_it_be(:authorized_project) { create(:project) }
    let_it_be(:authorized_project2) { create(:project) }
    let_it_be(:unauthorized_project) { create(:project) }

    let_it_be(:issue) { create(:issue, project: authorized_project) }

    let_it_be(:authorized_feature_flag) { create(:operations_feature_flag, project: authorized_project) }
    let_it_be(:authorized_feature_flag_b) { create(:operations_feature_flag, project: authorized_project2) }

    let_it_be(:unauthorized_feature_flag) { create(:operations_feature_flag, project: unauthorized_project) }

    let_it_be(:issue_link_a) { create(:feature_flag_issue, issue: issue, feature_flag: authorized_feature_flag) }
    let_it_be(:issue_link_b) { create(:feature_flag_issue, issue: issue, feature_flag: unauthorized_feature_flag) }
    let_it_be(:issue_link_c) { create(:feature_flag_issue, issue: issue, feature_flag: authorized_feature_flag_b) }

    before_all do
      authorized_project.add_developer(user)
      authorized_project2.add_developer(user)
    end

    it 'returns only authorized related feature flags for a given user' do
      expect(issue.related_feature_flags(user)).to contain_exactly(authorized_feature_flag, authorized_feature_flag_b)
    end

    describe 'when a user cannot read cross project' do
      it 'only returns feature_flags within the same project' do
        expect(Ability).to receive(:allowed?).with(user, :read_feature_flag, authorized_feature_flag).and_return(true)
        expect(Ability).to receive(:allowed?).with(user, :read_cross_project).and_return(false)

        expect(issue.related_feature_flags(user))
          .to contain_exactly(authorized_feature_flag)
      end
    end
  end

  describe '.with_issue_type' do
    let_it_be(:project) { create(:project) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:test_case) { create(:quality_test_case, project: project) }

    it 'gives issues with test case type' do
      expect(described_class.with_issue_type('test_case'))
        .to contain_exactly(test_case)
    end

    it 'gives issues with the given issue types list' do
      expect(described_class.with_issue_type(%w(issue test_case)))
        .to contain_exactly(issue, test_case)
    end
  end

  describe '#update_cached_metadata' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:epic) { create(:epic, group: group) }

    before do
      stub_licensed_features(epics: true)
    end

    context 'when epic is not assigned' do
      let(:issue) { build(:issue, project: project) }

      it 'does nothing' do
        expect(::Epics::UpdateCachedMetadataWorker).not_to receive(:perform_async)

        issue.save!
      end
    end

    context 'when creating new issue' do
      let(:issue) { build(:issue, project: project, epic: epic) }

      it 'schedules cache update for epic' do
        expect(::Epics::UpdateCachedMetadataWorker).to receive(:perform_async).with([epic.id]).once

        issue.save!
      end
    end

    context 'when updating an existing issue' do
      let_it_be(:issue) { create(:issue, project: project, epic: epic) }

      it 'schedules cache update for epic if state is changed' do
        issue.state = :closed

        expect(::Epics::UpdateCachedMetadataWorker).to receive(:perform_async).with([epic.id]).once

        issue.save!
      end

      it 'schedules cache update for epic if weight is changed' do
        issue.weight = 2

        expect(::Epics::UpdateCachedMetadataWorker).to receive(:perform_async).with([epic.id]).once

        issue.save!
      end

      it 'does nothing when unrelated attributes are changed' do
        issue.title = 'new title'

        expect(::Epics::UpdateCachedMetadataWorker).not_to receive(:perform_async)

        issue.save!
      end

      it 'schedules cache update for epic if issue is destroyed' do
        issue.reload

        expect(::Epics::UpdateCachedMetadataWorker).to receive(:perform_async).with([epic.id]).once

        issue.destroy!
      end
    end
  end

  describe "#has_epic?" do
    let(:issue) { build(:issue, epic: epic) }

    subject(:has_epic) { issue.has_epic? }

    context 'when when there is no associated epic' do
      let(:epic) { nil }

      it { is_expected.to eq false }
    end

    context 'when when there is an associated epic' do
      let(:epic) { build(:epic) }

      it { is_expected.to eq true }
    end
  end

  describe '#allowed_work_item_type_change' do
    let_it_be(:epic) { create(:epic) }

    context 'when it is part of an epic' do
      it 'is not possible to change from issue to incident' do
        issue = create(:issue, :issue, epic: epic)
        issue.assign_attributes(work_item_type: WorkItems::Type.default_by_type(:incident), issue_type: :incident)

        expect(issue).not_to be_valid
        expect(issue.errors[:work_item_type_id])
          .to include(_('can not be changed when assigned to an epic'))
      end

      it 'is possible to change back from incident to issue' do
        issue = create(:issue, :incident, epic: epic)
        issue.assign_attributes(work_item_type: WorkItems::Type.default_by_type(:issue), issue_type: :issue)

        expect(issue).to be_valid
      end
    end

    context 'when it is not part of an epic' do
      it 'is possible to change between types' do
        issue = create(:issue, :issue)
        issue.assign_attributes(work_item_type: WorkItems::Type.default_by_type(:incident), issue_type: :incident)

        expect(issue).to be_valid
      end
    end
  end

  it_behaves_like 'resource with exportable associations' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:other_group) { create(:group, :private) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be_with_reload(:resource) { create(:issue, project: project) }
    let_it_be(:epic) { create(:epic, group: group) }
    let_it_be(:cross_group_epic) { create(:epic, group: other_group) }
    let_it_be(:epic_issue) { create(:epic_issue, issue: resource, epic: cross_group_epic) }

    let_it_be(:readable_note) do
      text = "added epic #{epic.to_reference}"
      note = create(:system_note, noteable: resource, project: project, note: text)
      create(:system_note_metadata, note: note, action: 'relate')
      note
    end

    let_it_be(:restricted_note) do
      text = "added epic #{cross_group_epic.to_reference(full: true)}"
      note = create(:system_note, noteable: resource, project: project, note: text)
      create(:system_note_metadata, note: note, action: 'relate')
      note
    end

    let(:single_association) { :epic_issue }
    let(:stubbed_features) { { epics: true } }
  end
end
