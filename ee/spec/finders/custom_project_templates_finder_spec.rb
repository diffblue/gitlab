# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomProjectTemplatesFinder do
  let_it_be(:user) { create(:user) }

  let(:base_params) { { current_user: user } }
  let(:params) { {} }

  subject { described_class.new(**base_params.merge(params)) }

  it 'returns an empty relation if group is not set' do
    expect(subject.execute).to be_empty
  end

  context 'when group with custom project templates is set' do
    let_it_be(:group) { create(:group) }

    before do
      stub_ee_application_setting(custom_project_templates_group_id: group.id)
    end

    it 'returns an empty relation if group has no available project templates' do
      expect(group.projects).to be_empty
      expect(subject.execute).to be_empty
    end

    it 'ignores pages permissions as they are not exported' do
      project = create(:project, :internal, :metrics_dashboard_enabled, namespace: group, pages_access_level: ProjectFeature::PRIVATE)

      expect(subject.execute).to eq([project])
    end

    context 'when the group has projects' do
      using RSpec::Parameterized::TableSyntax

      let_it_be_with_reload(:private_project) { create :project, :metrics_dashboard_enabled, :private, namespace: group, name: 'private' }
      let_it_be_with_reload(:internal_project) { create :project, :metrics_dashboard_enabled, :internal, namespace: group, name: 'internal' }
      let_it_be_with_reload(:public_project) { create :project, :metrics_dashboard_enabled, :public, namespace: group, name: 'public' }

      where(:issues_access_level, :minimal_user_access, :available_templates) do
        :disabled | :no_access | %w[public internal]
        :disabled | :guest     | %w[public internal private]
        :private  | :guest     | %w[public internal private]
        :private  | :no_access | %w[]
        :enabled  | :guest     | %w[public internal private]
        :enabled  | :no_access | %w[public internal]
      end

      with_them do
        context "when templates have the issues feature #{params[:issues_access_level]}" do
          before do
            private_project.project_feature.update!(issues_access_level: ProjectFeature::STRING_OPTIONS[issues_access_level])
            internal_project.project_feature.update!(issues_access_level: ProjectFeature::STRING_OPTIONS[issues_access_level])
            public_project.project_feature.update!(issues_access_level: ProjectFeature::STRING_OPTIONS[issues_access_level])
          end

          it "returns #{params[:available_templates].join(', ')} projects to users with #{params[:minimal_user_access]} to the project" do
            unless minimal_user_access == :no_access
              public_project.add_member(user, minimal_user_access)
              internal_project.add_member(user, minimal_user_access)
              private_project.add_member(user, minimal_user_access)
            end

            expect(subject.execute.pluck(:name)).to match_array(available_templates)
          end

          it "returns #{params[:available_templates].join(', ')} projects to users with #{params[:minimal_user_access]} to the group" do
            unless minimal_user_access == :no_access
              group.add_member(user, minimal_user_access)
            end

            expect(subject.execute.pluck(:name)).to match_array(available_templates)
          end
        end
      end

      context 'filtering the results' do
        let_it_be(:other_public_project) { create :project, :metrics_dashboard_enabled, :public, namespace: group, name: 'other public' }

        it 'allows to search available project templates by name' do
          params[:search] = 'publi'

          expect(subject.execute).to contain_exactly(public_project, other_public_project)
        end

        it 'filters by single project ID' do
          params[:project_id] = public_project.id

          expect(subject.execute).to contain_exactly(public_project)
        end

        it 'filters by list of project IDs' do
          params[:project_id] = [public_project.id, other_public_project.id]

          expect(subject.execute).to contain_exactly(public_project, other_public_project)
        end

        it 'does not return inaccessible projects' do
          params[:project_id] = private_project.id

          expect(subject.execute).to be_empty
        end
      end
    end
  end
end
