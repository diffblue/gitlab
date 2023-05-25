# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::Projects::CreateService, feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user, user.ops_dashboard_projects, feature: feature, ability: ability) }
  let(:feature) { :operations_dashboard }
  let(:ability) { nil }
  let(:project) { create(:project) }

  describe '#execute' do
    let(:projects_finder) { double(ProjectsFinder) }
    let(:result) { service.execute(input) }
    let(:feature_available) { true }
    let(:permission_available) { false }

    before do
      allow(ProjectsFinder)
        .to receive(:new).with(current_user: user, project_ids_relation: input, params: { min_access_level: ProjectMember::DEVELOPER }).and_return(projects_finder)
      allow(projects_finder)
        .to receive(:execute).and_return(output)
      allow(project).to receive(:feature_available?).and_return(feature_available)
      allow(user).to receive(:can?).and_return(permission_available)
    end

    context 'with projects' do
      let(:output) { [project] }

      context 'with integer id' do
        let(:input) { [project.id] }

        it 'adds a project' do
          expect(result).to eq(expected_result(added_project_ids: [project.id]))
        end
      end

      context 'with string id' do
        let(:input) { [project.id.to_s] }

        it 'adds a project' do
          expect(result).to eq(expected_result(added_project_ids: [project.id]))
        end
      end

      context 'with a project that does not exist' do
        let(:input) { [non_existing_record_id] }
        let(:output) { [] }

        it 'does not add a not found project' do
          expect(result).to eq(expected_result(not_found_project_ids: [non_existing_record_id]))
        end
      end

      context 'when feature name is provided' do
        context 'with project without provided feature enabled' do
          let(:input) { [project.id] }
          let(:feature_available) { false }
          let(:ability) { nil }

          it 'checks if feature is available' do
            expect(project).to receive(:feature_available?).and_return(false)
            result
          end

          it 'does not check if user has access to the project with given ability' do
            expect(user).not_to receive(:can?).with(ability, project)
            result
          end

          it 'does not add a not licensed project' do
            expect(result).to eq(expected_result(not_licensed_project_ids: [project.id]))
          end
        end
      end

      context 'when ability name is provided' do
        context 'with project for which user has no permission' do
          let(:input) { [project.id] }
          let(:feature) { nil }
          let(:ability) { :read_security_resource }
          let(:permission_available) { false }

          it 'does not check if feature is available' do
            expect(project).not_to receive(:feature_available?)
            result
          end

          it 'checks if user has access to the project with given ability' do
            expect(user).to receive(:can?).with(ability, project).and_return(false)
            result
          end

          it 'does not add a not licensed project' do
            expect(result).to eq(expected_result(not_licensed_project_ids: [project.id]))
          end
        end
      end

      context 'with repeating project id' do
        let(:input) { [project.id, project.id] }

        it 'adds a project only once' do
          expect(result).to eq(expected_result(added_project_ids: [project.id]))
        end
      end

      context 'with already added project' do
        let(:input) { [project.id] }

        before do
          user.ops_dashboard_projects << project
        end

        it 'does not add duplicates' do
          expect(result).to eq(expected_result(duplicate_project_ids: [project.id]))
        end
      end
    end
  end

  private

  def expected_result(
    added_project_ids: [],
    not_found_project_ids: [],
    not_licensed_project_ids: [],
    duplicate_project_ids: []
  )
    described_class::Result.new(
      added_project_ids, not_found_project_ids, not_licensed_project_ids, duplicate_project_ids
    )
  end
end
