# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ComplianceStandards::Adherence, type: :model, feature_category: :compliance_management do
  describe 'validations' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group_project) { create(:project, namespace: group) }
    let_it_be(:adherence) { create(:compliance_standards_adherence, project: group_project) }

    message = 'already has this check defined for this standard'

    it { is_expected.to validate_uniqueness_of(:project).scoped_to([:check_name, :standard]).with_message(message) }
    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:check_name) }
    it { is_expected.to validate_presence_of(:standard) }
    it { is_expected.to validate_presence_of(:status) }

    describe 'namespace_is_group' do
      context 'when project belongs to a group' do
        let_it_be(:project) { create(:project, :in_group) }
        let_it_be(:adherence) { build(:compliance_standards_adherence, project: project) }

        it 'is valid' do
          expect(adherence).to be_valid
        end
      end

      context 'when project belongs to a user namespace' do
        let_it_be(:user) { create(:user) }
        let_it_be(:project) { create(:project, namespace: user.namespace) }
        let_it_be(:adherence) { build(:compliance_standards_adherence, project: project) }

        it 'is invalid' do
          expect(adherence).not_to be_valid
          expect(adherence.errors[:namespace_id]).to include('must be a group, user namespaces are not supported.')
        end
      end

      context 'when namespace is a subgroup' do
        let_it_be(:project) { create(:project, :in_subgroup) }
        let_it_be(:adherence) { build(:compliance_standards_adherence, project: project) }

        it 'is valid' do
          expect(adherence).to be_valid
        end
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:namespace) }
  end

  describe "enums" do
    status_values = ::Enums::Projects::ComplianceStandards::Adherence.status
    check_name_values = ::Enums::Projects::ComplianceStandards::Adherence.check_name
    standard_values = ::Enums::Projects::ComplianceStandards::Adherence.standard

    it { is_expected.to define_enum_for(:status).with_values(status_values) }
    it { is_expected.to define_enum_for(:check_name).with_values(check_name_values) }
    it { is_expected.to define_enum_for(:standard).with_values(standard_values) }
  end

  describe 'scopes' do
    let_it_be(:project_1) { create(:project, :in_group) }
    let_it_be(:project_2) { create(:project, :in_group) }
    let_it_be(:subgroup) { create(:group, parent: project_1.group) }
    let_it_be(:subgroup_project) { create(:project, namespace: subgroup) }

    let_it_be(:adherence_1) do
      create(:compliance_standards_adherence, project: project_1,
        check_name: :prevent_approval_by_merge_request_author, standard: :gitlab)
    end

    let_it_be(:adherence_2) do
      create(:compliance_standards_adherence, project: project_2,
        check_name: :prevent_approval_by_merge_request_author, standard: :gitlab)
    end

    let_it_be(:adherence_3) { create(:compliance_standards_adherence, project: subgroup_project) }

    describe '.for_projects' do
      it 'returns the adherence records for the specified projects', :aggregate_failures do
        expect(described_class.for_projects(project_1.id)).to contain_exactly(adherence_1)
        expect(described_class.for_projects([project_1.id, project_2.id])).to contain_exactly(adherence_1, adherence_2)
      end
    end

    describe '.for_check_name' do
      it 'returns the adherence records for the specified check_name' do
        expect(described_class.for_check_name(:prevent_approval_by_merge_request_author))
          .to contain_exactly(adherence_1, adherence_2, adherence_3)
      end
    end

    describe '.for_standard' do
      it 'returns the adherence records for the specified standard' do
        expect(described_class.for_standard(:gitlab)).to contain_exactly(adherence_1, adherence_2, adherence_3)
      end
    end

    describe '.for_group' do
      it 'returns the adherence records for the specified group', :aggregate_failures do
        expect(described_class.for_group(project_1.group.id)).to contain_exactly(adherence_1)
        expect(described_class.for_group(project_2.group.id)).to contain_exactly(adherence_2)
      end
    end

    describe '.for_group_and_its_subgroups' do
      it 'returns the adherence records for the specified group and its subgroups', :aggregate_failures do
        expect(described_class.for_group_and_its_subgroups(project_1.group))
          .to contain_exactly(adherence_1, adherence_3)

        expect(described_class.for_group_and_its_subgroups(project_2.group)).to contain_exactly(adherence_2)
      end
    end
  end
end
