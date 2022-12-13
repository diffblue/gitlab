# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Exporting Requirements', feature_category: :requirements_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:requirement) { create(:work_item, :requirement, project: project).requirement }

  let(:attributes) { { state: 'OPENED', author_username: [current_user.username], sort: :CREATED_ASC, search: requirement.title } }
  let(:mutation) do
    params = { project_path: project.full_path }.merge(attributes)

    graphql_mutation(:export_requirements, params)
  end

  def mutation_response
    graphql_mutation_response(:export_requirements)
  end

  shared_examples 'requirements export fails' do
    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not schedule export job' do
      expect(IssuableExportCsvWorker).not_to receive(:perform_async)
    end
  end

  context 'when the user does not have permission' do
    before do
      stub_licensed_features(requirements: true)
    end

    it_behaves_like 'requirements export fails'
  end

  context 'when the user has permission' do
    before do
      project.add_reporter(current_user)
    end

    context 'when requirements are disabled' do
      before do
        stub_licensed_features(requirements: false)
      end

      it_behaves_like 'requirements export fails'
    end

    context 'when requirements are enabled' do
      before do
        stub_licensed_features(requirements: true)
      end

      it 'schedules job to export requirements', :aggregate_failures do
        args = {
          author_username: [current_user.username],
          search: requirement.title,
          sort: :created_asc,
          state: 'opened'
        }
        expect(IssuableExportCsvWorker)
          .to receive(:perform_async).with(:requirement, current_user.id, project.id, args)

        post_graphql_mutation(mutation, current_user: current_user)
        expect(mutation_response['errors']).to be_empty
      end
    end
  end
end
