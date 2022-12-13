# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Lock/unlock project's file path", feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:attributes) { { file_path: file_path, lock: lock } }
  let(:file_path) { 'README.md' }
  let(:lock) { true }
  let(:mutation) do
    params = { project_path: project.full_path }.merge(attributes)

    graphql_mutation(:project_set_locked, params) do
      <<-QL.strip_heredoc
        project {
          id
          pathLocks {
            nodes {
              path
            }
          }
        }
        errors
      QL
    end
  end

  def mutation_response
    graphql_mutation_response(:project_set_locked)
  end

  context 'when the user does not have permission' do
    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create requirement' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change { project.path_locks.count }
    end
  end

  context 'when the user has permission' do
    before do
      project.add_developer(current_user)
    end

    it 'creates the path lock' do
      post_graphql_mutation(mutation, current_user: current_user)

      project_hash = mutation_response['project']

      expect(project_hash.dig('pathLocks', 'nodes', 0, 'path')).to eq(file_path)
    end

    context 'when there are validation errors' do
      let(:lock) { false }

      before do
        create(:path_lock, project: project, path: file_path)
      end

      it_behaves_like 'a mutation that returns errors in the response',
                      errors: ['You have no permissions']
    end
  end
end
