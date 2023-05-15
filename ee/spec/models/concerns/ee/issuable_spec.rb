# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Issuable do
  describe "Validation" do
    context 'general validations' do
      subject { build(:epic) }

      before do
        allow(InternalId).to receive(:generate_next).and_return(nil)
      end

      it { is_expected.to validate_presence_of(:author) }
      it { is_expected.to validate_presence_of(:title) }
      it { is_expected.to validate_length_of(:title).is_at_most(::Issuable::TITLE_LENGTH_MAX) }

      it_behaves_like 'validates description length with custom validation' do
        before do
          allow(InternalId).to receive(:generate_next).and_call_original
        end
      end

      it_behaves_like 'truncates the description to its allowed maximum length on import'
    end
  end

  describe '#matches_cross_reference_regex?' do
    context "epic description with long path string" do
      let(:mentionable) { build(:epic, description: "/a" * 50000) }

      it_behaves_like 'matches_cross_reference_regex? fails fast'
    end
  end

  describe '#supports_epic?' do
    let(:group) { build_stubbed(:group) }
    let(:project_with_group) { build_stubbed(:project, group: group) }
    let(:project_without_group) { build_stubbed(:project) }

    where(:issuable_type, :project, :supports_epic) do
      [
        [:issue, :project_with_group, true],
        [:issue, :project_without_group, false],
        [:incident, :project_with_group, false],
        [:incident, :project_without_group, false],
        [:merge_request, :project_with_group, false],
        [:merge_request, :project_without_group, false]
      ]
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type, project: send(project)) }

      subject { issuable.supports_epic? }

      it { is_expected.to eq(supports_epic) }
    end
  end

  describe '#weight_available?' do
    let(:group) { build_stubbed(:group) }
    let(:project_with_group) { build_stubbed(:project, group: group) }
    let(:project_without_group) { build_stubbed(:project) }

    where(:issuable_type, :project, :weight_available) do
      [
        [:issue, :project_with_group, true],
        [:issue, :project_without_group, true],
        [:incident, :project_with_group, false],
        [:incident, :project_without_group, false],
        [:merge_request, :project_with_group, false],
        [:merge_request, :project_without_group, false]
      ]
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type, project: send(project)) }

      subject { issuable.weight_available? }

      it { is_expected.to eq(weight_available) }
    end
  end

  describe '#supports_iterations?' do
    let(:group) { build_stubbed(:group) }
    let(:project_with_group) { build_stubbed(:project, group: group) }
    let(:project_without_group) { build_stubbed(:project) }

    where(:issuable_type, :project, :supports_iterations) do
      [
        [:issue, :project_with_group, true],
        [:issue, :project_without_group, true],
        [:incident, :project_with_group, false],
        [:incident, :project_without_group, false],
        [:merge_request, :project_with_group, false],
        [:merge_request, :project_without_group, false]
      ]
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type, project: send(project)) }

      subject { issuable.supports_iterations? }

      it { is_expected.to eq(supports_iterations) }
    end
  end

  describe '#send_to_ai?' do
    context 'for issues' do
      where(:confidentiality, :visibility, :third_party_ai_features_enabled, :result) do
        [
          [true, :public, false, false],
          [true, :public, true, false],
          [true, :private, false, false],
          [false, :private, false, false],
          [false, :private, true, false],
          [false, :public, true, true]
        ]
      end

      with_them do
        let(:project) { build_stubbed(:project, visibility) }
        let(:issuable) { build_stubbed(:issue, confidential: confidentiality, project: project) }

        before do
          allow(project.namespace).to receive(:third_party_ai_features_enabled).and_return(third_party_ai_features_enabled)
        end

        subject { issuable.send_to_ai? }

        it { is_expected.to eq(result) }
      end
    end

    context 'for epics' do
      where(:confidentiality, :visibility, :result) do
        [
          [true, :public, false],
          [false, :private, false],
          [false, :public, true]
        ]
      end
      with_them do
        let(:group) { build_stubbed(:group, visibility) }
        let(:issuable) { build_stubbed(:epic, confidential: confidentiality, group: group) }

        subject { issuable.send_to_ai? }

        it { is_expected.to eq(result) }
      end
    end

    context 'for merge requests' do
      where(:visibility, :result) do
        [
          [Gitlab::VisibilityLevel::PUBLIC, true],
          [Gitlab::VisibilityLevel::INTERNAL, false],
          [Gitlab::VisibilityLevel::PRIVATE, false]
        ]
      end

      with_them do
        let(:project) { build_stubbed(:project, visibility_level: visibility) }
        let(:issuable) { build_stubbed(:merge_request, project: project) }

        subject { issuable.send_to_ai? }

        it { is_expected.to eq(result) }
      end
    end
  end

  describe '#supports_confidentiality?' do
    let(:issuable) { build_stubbed(:epic) }

    subject { issuable.supports_confidentiality? }

    it { is_expected.to be_truthy }
  end

  describe '#escalation_policies_available?' do
    where(:issuable_type, :oncall_schedules_enabled, :escalation_policies_enabled, :available) do
      [
        [:issue, true, true, false],
        [:incident, false, false, false],
        [:incident, true, false, false],
        [:incident, false, true, false],
        [:incident, true, true, true]
      ]
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type) }

      before do
        stub_licensed_features(oncall_schedules: oncall_schedules_enabled, escalation_policies: escalation_policies_enabled)
      end

      subject { issuable.escalation_policies_available? }

      it { is_expected.to eq(available) }
    end
  end

  describe '#to_hook_data' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:escalation_policy) { create(:incident_management_escalation_policy, project: project) }

    let(:builder) { double }

    context 'escalation status is updated' do
      let(:issue) { create(:incident, :with_escalation_status) }
      let(:policy_changes) { { policy: escalation_policy, escalations_started_at: Time.current } }
      let(:status_changes) { {} }
      let(:old_associations) { { escalation_status: :triggered, escalation_policy: nil } }
      let(:expected_policy_hash) { { 'id' => escalation_policy.id, 'name' => escalation_policy.name } }

      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: true)

        issue.escalation_status.update!(**policy_changes, **status_changes)

        expect(Gitlab::DataBuilder::Issuable).to receive(:new).with(issue).and_return(builder)
      end

      it 'delegates to Gitlab::DataBuilder::Issuable#build' do
        expect(builder).to receive(:build).with(
          user: user,
          changes: hash_including(
            'escalation_policy' => [nil, expected_policy_hash]
          )
        )

        issue.to_hook_data(user, old_associations: old_associations)
      end

      context 'with policy and status changes' do
        let(:status_changes) { { status: IncidentManagement::IssuableEscalationStatus::STATUSES[:acknowledged] } }

        it 'includes both status and policy fields simultaneously' do
          expect(builder).to receive(:build).with(
            user: user,
            changes: hash_including(
              'escalation_status' => %i(triggered acknowledged),
              'escalation_policy' => [nil, expected_policy_hash]
            )
          )

          issue.to_hook_data(user, old_associations: old_associations)
        end
      end
    end
  end

  describe '#allows_scoped_labels?' do
    let_it_be(:project) { build_stubbed(:project) }

    it 'allows scoped labels with licensed project' do
      issue = build_stubbed(:issue, project: project)

      stub_licensed_features(scoped_labels: true)

      expect(issue.allows_scoped_labels?).to be(true)
    end

    it 'allows scoped labels with licensed group' do
      epic = build_stubbed(:epic, group: build_stubbed(:group))

      stub_licensed_features(scoped_labels: true)

      expect(epic.allows_scoped_labels?).to be(true)
    end

    it 'does not allow scoped labels without license' do
      issue = build_stubbed(:issue, project: project)

      stub_licensed_features(scoped_labels: false)

      expect(issue.allows_scoped_labels?).to be(false)
    end
  end

  describe '#issuable_resource_links_available?' do
    let_it_be(:project) { build_stubbed(:project) }

    it 'returns false for issuable type as issue' do
      issue = build_stubbed(:issue, project: project)

      stub_licensed_features(issuable_resource_links: true)

      expect(issue.issuable_resource_links_available?).to be(false)
    end

    it 'returns true for issuable type as incident' do
      issue = build_stubbed(:incident, project: project)

      stub_licensed_features(issuable_resource_links: true)

      expect(issue.issuable_resource_links_available?).to be(true)
    end

    it 'returns false when feature is not avaiable' do
      issue = build_stubbed(:incident, project: project)

      stub_licensed_features(issuable_resource_links: false)

      expect(issue.issuable_resource_links_available?).to be(false)
    end
  end
end
