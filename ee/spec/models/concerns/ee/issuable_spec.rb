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
      it { is_expected.to validate_length_of(:description).is_at_most(::Issuable::DESCRIPTION_LENGTH_MAX).on(:create) }

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

  describe '#escalation_policies_available?' do
    where(:issuable_type, :incident_escalations_enabled, :oncall_schedules_enabled, :escalation_policies_enabled, :available) do
      [
        [:issue, true, true, true, false],
        [:incident, false, false, false, false],
        [:incident, false, true, true, false],
        [:incident, true, false, false, false],
        [:incident, true, true, false, false],
        [:incident, true, false, true, false],
        [:incident, true, true, true, true]
      ]
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type) }

      before do
        stub_feature_flags(incident_escalations: incident_escalations_enabled)
        stub_licensed_features(oncall_schedules: oncall_schedules_enabled, escalation_policies: escalation_policies_enabled)
      end

      subject { issuable.escalation_policies_available? }

      it { is_expected.to eq(available) }
    end
  end
end
