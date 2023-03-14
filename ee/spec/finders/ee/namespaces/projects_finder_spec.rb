# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ProjectsFinder do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:namespace) { create(:group, :public) }
  let_it_be(:subgroup) { create(:group, parent: namespace) }
  let_it_be(:project_1) { create(:project, :public, group: namespace, path: 'project', name: 'Project') }
  let_it_be(:project_2) { create(:project, :public, group: namespace, path: 'test-project', name: 'Test Project') }
  let_it_be(:project_3) { create(:project, :public, group: subgroup, path: 'test-subgroup', name: 'Subgroup Project') }

  let(:params) { {} }

  let(:finder) { described_class.new(namespace: namespace, params: params, current_user: current_user) }

  subject(:projects) { finder.execute }

  describe '#execute' do
    context 'when compliance framework is present' do
      let_it_be(:framework_1) { create(:compliance_framework, namespace: namespace, name: "Test1") }
      let_it_be(:framework_settings_1) do
        create(:compliance_framework_project_setting, project: project_1, compliance_management_framework: framework_1)
      end

      let_it_be(:framework_2) { create(:compliance_framework, namespace: namespace, name: "Test2") }
      let_it_be(:framework_settings_2) do
        create(:compliance_framework_project_setting, project: project_2, compliance_management_framework: framework_2)
      end

      let_it_be(:other_namespace) { create(:group, :public) }
      let_it_be(:other_project) { create(:project, :public, group: other_namespace) }
      let_it_be(:other_framework) { create(:compliance_framework, namespace: other_namespace) }
      let_it_be(:other_framework_settings) do
        create(:compliance_framework_project_setting, project: other_project,
          compliance_management_framework: other_framework)
      end

      context 'when no filters are present' do
        it 'returns all projects' do
          expect(projects).to contain_exactly(project_1, project_2)
        end
      end

      context 'when compliance framework id is passed' do
        let(:params) { { compliance_framework_filters: { id: framework_id } } }

        context 'when compliance_framework_id is of valid framework' do
          let(:framework_id) { framework_1.id }

          it 'returns projects with compliance framework' do
            expect(projects).to contain_exactly(project_1)
          end
        end

        context 'when compliance_framework_id is of other namespace' do
          let(:framework_id) { other_framework.id }

          it 'returns no projects' do
            expect(projects).to be_empty
          end
        end

        context 'when provided with a non existing framework id' do
          let(:framework_id) { non_existing_record_id }

          it 'returns no projects' do
            expect(projects).to be_empty
          end
        end

        context 'when compliance_framework_id is nil ' do
          let(:framework_id) { nil }

          it 'returns all projects' do
            expect(projects).to contain_exactly(project_1, project_2)
          end
        end
      end

      context 'when negated compliance framework id param is passed' do
        let(:params) { { compliance_framework_filters: { not: { id: framework_id } } } }

        context 'when compliance_framework_id is of valid framework' do
          let(:framework_id) { framework_1.id }

          it "returns projects where compliance framework id is not framework's id or nil" do
            expect(projects).to contain_exactly(project_2)
          end
        end

        context 'when compliance_framework_id is of other namespace' do
          let(:framework_id) { other_framework.id }

          it 'returns all projects' do
            expect(projects).to contain_exactly(project_1, project_2)
          end
        end

        context 'when provided with a non existing framework id' do
          let(:framework_id) { non_existing_record_id }

          it 'returns all projects' do
            expect(projects).to contain_exactly(project_1, project_2)
          end
        end

        context 'when compliance_framework_id is nil ' do
          let(:framework_id) { nil }

          it 'returns all projects' do
            expect(projects).to contain_exactly(project_1, project_2)
          end
        end
      end

      context 'when both framework id and negated compliance framework id is passed' do
        let(:params) { { compliance_framework_filters: { id: framework_id, not: { id: not_framework_id } } } }

        context 'when both ids are same' do
          let(:framework_id) { framework_1.id }
          let(:not_framework_id) { framework_1.id }

          it 'returns projects with other compliance framework' do
            expect(projects).to be_empty
          end
        end

        context 'when both ids are different' do
          let(:framework_id) { framework_1.id }
          let(:not_framework_id) { framework_2.id }

          it 'returns projects with other compliance framework' do
            expect(projects).to contain_exactly(project_1)
          end
        end
      end
    end

    context 'has_vulnerabilities' do
      before do
        project_1.project_setting.update!(has_vulnerabilities: true)
      end

      context 'when has_vulnerabilities is provided' do
        let(:params) { { has_vulnerabilities: true } }

        it 'returns projects with vulnerabilities' do
          expect(projects).to contain_exactly(project_1)
        end
      end

      context 'when has_vulnerabilities is not provided' do
        it 'returns all projects' do
          expect(projects).to contain_exactly(project_1, project_2)
        end
      end
    end

    context 'sorting' do
      before do
        project_1.statistics.update!(lfs_objects_size: 11, repository_size: 10)
        project_2.statistics.update!(lfs_objects_size: 10, repository_size: 12)
      end

      context 'when sort equals :storage' do
        let(:params) { { sort: :storage } }

        it 'returns projects sorted by storage' do
          expect(projects).to eq [project_2, project_1]
        end
      end

      context 'when sort does not equal :storage' do
        it 'returns all projects' do
          expect(projects).to match_array [project_1, project_2]
        end
      end
    end

    context 'has_code_coverage' do
      context 'when has_code_coverage is provided' do
        let(:params) { { has_code_coverage: true } }

        before_all do
          create(:project_ci_feature_usage, feature: :code_coverage, project: project_1, default_branch: true)
          create(:ci_daily_build_group_report_result, project: project_1, default_branch: true)
          create(:project_ci_feature_usage, feature: :code_coverage, project: project_2, default_branch: false)
          create(:ci_daily_build_group_report_result, project: project_2, default_branch: false)
        end

        it 'returns projects with code coverage on default branch based on ci feature usages' do
          record = ActiveRecord::QueryRecorder.new do
            expect(projects).to contain_exactly(project_1)
          end

          queried_ci_table = record.log.any? { |l| l.include?('ci_daily_build_group_report_results') }

          expect(queried_ci_table).to eq(false)
        end
      end

      context 'when has_code_coverage is not provided' do
        it 'returns all projects' do
          expect(projects).to contain_exactly(project_1, project_2)
        end
      end
    end
  end
end
