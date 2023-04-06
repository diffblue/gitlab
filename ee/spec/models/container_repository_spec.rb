# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRepository, :saas do
  include_examples 'a replicable model with a separate table for verification state' do
    let(:verifiable_model_record) { build(:container_repository) }
    let(:unverifiable_model_record) { nil }
  end

  describe '.with_target_import_tier' do
    let_it_be(:valid_container_repository) { create(:container_repository, migration_plan: 'free') }

    let_it_be(:gitlab_namespace) { create(:namespace, path: 'gitlab-org') }
    let_it_be(:gitlab_project) { create(:project, namespace: gitlab_namespace) }
    let_it_be(:gitlab_container_repository) { create(:container_repository, project: gitlab_project) }

    let_it_be(:ultimate_container_repository) { create(:container_repository, migration_plan: 'ultimate') }

    subject { described_class.with_target_import_tier }

    before do
      stub_application_setting(container_registry_import_target_plan: valid_container_repository.migration_plan)
    end

    context 'all_plans disabled' do
      before do
        stub_feature_flags(container_registry_migration_phase2_all_plans: false)
      end

      context 'limit_gitlab_org enabled' do
        it { is_expected.to contain_exactly(gitlab_container_repository) }

        context 'with sub group named gitlab-org' do
          let_it_be(:root) { create(:group, path: 'test-root') }
          let_it_be(:subgroup) { create(:group, path: 'gitlab-org', parent: root) }
          let_it_be(:subproject) { create(:project, namespace: subgroup) }
          let_it_be(:subgroup_repository) { create(:container_repository, project: subproject) }

          it { is_expected.to contain_exactly(gitlab_container_repository) }
        end

        context 'with no gitlab root namespace' do
          before do
            expect(::Namespace).to receive(:by_path).with('gitlab-org').and_return(nil)
          end

          it { is_expected.to be_empty }
        end
      end

      context 'limit_gitlab_org disabled' do
        before do
          stub_feature_flags(container_registry_migration_limit_gitlab_org: false)
        end

        it { is_expected.to contain_exactly(valid_container_repository, gitlab_container_repository) }
      end
    end

    context 'all_plans and limit_gitlab_org enabled' do
      it { is_expected.to contain_exactly(valid_container_repository, ultimate_container_repository, gitlab_container_repository) }
    end
  end

  describe '.ready_for_import' do
    include_context 'importable repositories'

    let_it_be(:ultimate_container_repository) { create(:container_repository, migration_plan: 'ultimate', created_at: 2.days.ago) }

    subject { described_class.ready_for_import }

    before do
      stub_application_setting(container_registry_import_target_plan: valid_container_repository.migration_plan)
    end

    it { is_expected.to contain_exactly(valid_container_repository, valid_container_repository2) }
  end

  describe '#push_blob' do
    let_it_be(:gitlab_container_repository) { create(:container_repository) }

    it "calls client's push blob with path passed" do
      client = instance_double("ContainerRegistry::Client")
      allow(gitlab_container_repository).to receive(:client).and_return(client)

      expect(client).to receive(:push_blob).with(gitlab_container_repository.path, 'a123cd', ['body'], 32456)

      gitlab_container_repository.push_blob('a123cd', ['body'], 32456)
    end
  end

  describe '.search' do
    let_it_be(:container_repository1) { create(:container_repository) }
    let_it_be(:container_repository2) { create(:container_repository) }
    let_it_be(:container_repository3) { create(:container_repository) }

    context 'when search query is empty' do
      it 'returns all records' do
        result = described_class.search('')

        expect(result).to contain_exactly(container_repository1, container_repository2, container_repository3)
      end
    end

    context 'when search query is not empty' do
      context 'without matches' do
        it 'filters all container repositories' do
          result = described_class.search('something_that_does_not_exist')

          expect(result).to be_empty
        end
      end

      context 'with matches' do
        context 'with matches by attributes' do
          where(:searchable_attributes) { described_class::EE_SEARCHABLE_ATTRIBUTES }

          before do
            # Use update_column to bypass attribute validations like regex formatting, checksum, etc.
            container_repository1.update_column(searchable_attributes, 'any_keyword')
          end

          with_them do
            it do
              result = described_class.search('any_keyword')

              expect(result).to contain_exactly(container_repository1)
            end
          end
        end
      end
    end
  end
end
