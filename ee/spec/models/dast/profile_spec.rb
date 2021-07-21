# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::Profile, type: :model do
  let_it_be(:project) { create(:project) }

  subject { create(:dast_profile, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:dast_site_profile) }
    it { is_expected.to belong_to(:dast_scanner_profile) }
    it { is_expected.to have_many(:secret_variables).through(:dast_site_profile).class_name('Dast::SiteProfileSecretVariable') }
    it { is_expected.to have_many(:dast_profiles_pipelines).class_name('Dast::ProfilesPipeline').with_foreign_key(:dast_profile_id).inverse_of(:dast_profile) }
    it { is_expected.to have_many(:ci_pipelines).through(:dast_profiles_pipelines).class_name('Ci::Pipeline') }
    it { is_expected.to have_many(:dast_profile_schedules).class_name('Dast::ProfileSchedule').with_foreign_key(:dast_profile_id).inverse_of(:dast_profile) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }
    it { is_expected.to validate_length_of(:branch_name).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:dast_site_profile_id) }
    it { is_expected.to validate_presence_of(:dast_scanner_profile_id) }
    it { is_expected.to validate_presence_of(:name) }

    shared_examples 'the project_id does not match' do
      let(:association_name) { association.class.underscore }

      subject { build(:dast_profile, project: project, association_name => association) }

      before do
        association.project_id = non_existing_record_id
      end

      it 'is not valid', :aggregate_failures do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to include("Project must match #{association_name}.project_id")
      end
    end

    context 'when the project_id and dast_site_profile.project_id do not match' do
      let(:association) { build(:dast_site_profile) }

      it_behaves_like 'the project_id does not match'
    end

    context 'when the project_id and dast_scanner_profile.project_id do not match' do
      let(:association) { build(:dast_scanner_profile) }

      it_behaves_like 'the project_id does not match'
    end

    context 'when the description is nil' do
      subject { build(:dast_profile, description: nil) }

      it 'is not valid' do
        aggregate_failures do
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages).to include('Description can\'t be nil')
        end
      end
    end

    context 'when a branch_name is specified but the project does not have a respository' do
      subject { build(:dast_profile, branch_name: SecureRandom.hex) }

      it 'is not valid', :aggregate_failures do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to include('Project must have a repository')
        expect(subject.errors.full_messages).not_to include('Branch name can\'t reference a branch that does not exist')
      end
    end

    context 'when a branch_name is specified but the project does not have a respository' do
      let_it_be(:project) { create(:project, :repository) }

      subject { build(:dast_profile, project: project, branch_name: SecureRandom.hex) }

      it 'is not valid', :aggregate_failures do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).not_to include('Project must have a repository')
        expect(subject.errors.full_messages).to include('Branch name can\'t reference a branch that does not exist')
      end
    end
  end

  describe 'scopes' do
    describe 'by_project_id' do
      it 'includes the correct records' do
        another_dast_profile = create(:dast_profile)

        result = described_class.by_project_id(subject.project_id)

        aggregate_failures do
          expect(result).to include(subject)
          expect(result).not_to include(another_dast_profile)
        end
      end
    end
  end

  describe 'instance methods' do
    describe '#branch' do
      context 'when the associated project does not have a repository' do
        it 'returns nil' do
          expect(subject.branch).to be_nil
        end
      end

      context 'when the associated project has a repository' do
        let_it_be(:project) { create(:project, :repository) }

        subject { create(:dast_profile, project: project) }

        it 'returns a Dast::Branch' do
          expect(subject.branch).to be_a(Dast::Branch)
        end
      end
    end

    describe '#secret_ci_variables' do
      it { is_expected.to delegate_method(:secret_ci_variables).to(:dast_site_profile) }
    end
  end
end
