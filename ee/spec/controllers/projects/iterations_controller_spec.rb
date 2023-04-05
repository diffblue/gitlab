# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IterationsController, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  shared_examples 'iterations license is not available' do
    before do
      stub_licensed_features(iterations: false)

      project.add_developer(user)

      sign_in(user)
    end

    it_behaves_like 'returning response status', :not_found
  end

  shared_examples 'user is unauthorized' do
    before do
      sign_in(user)
    end

    it_behaves_like 'returning response status', :not_found
  end

  shared_examples 'project is under user namespace' do
    let_it_be(:project) { create(:project, namespace: user.namespace) }

    before do
      stub_licensed_features(iterations: true)
      sign_in(user)
    end

    it_behaves_like 'returning response status', :not_found
  end

  describe 'index' do
    subject { get :index, params: { namespace_id: project.namespace, project_id: project } }

    it_behaves_like 'iterations license is not available'
    it_behaves_like 'user is unauthorized'
    it_behaves_like 'project is under user namespace'

    context 'when user is authorized' do
      before do
        stub_licensed_features(iterations: true)

        project.add_developer(user)
        sign_in(user)
      end

      it 'redirects to the project iteration cadence index path' do
        subject

        expect(response).to redirect_to(project_iteration_cadences_path(project))
      end
    end
  end

  describe 'show' do
    let_it_be(:cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:iteration) { create(:iteration, iterations_cadence: cadence) }

    subject do
      get :show, params: {
        namespace_id: project.namespace,
        project_id: project,
        id: iteration.id
      }
    end

    it_behaves_like 'iterations license is not available'
    it_behaves_like 'user is unauthorized'
    it_behaves_like 'project is under user namespace'

    context 'when user is authorized' do
      before do
        stub_licensed_features(iterations: true)

        project.add_developer(user)
        sign_in(user)
      end

      context 'when current user cannot view the requested iteration' do
        let_it_be(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence)) }

        it_behaves_like 'returning response status', :not_found
      end

      context 'when current user can view the requested iteration' do
        it 'redirects to the project iteration cadence iteration show path' do
          subject

          expect(response).to redirect_to(
            project_iteration_cadence_iteration_path(
              project,
              iteration_cadence_id: iteration.iterations_cadence_id,
              id: iteration.id
            )
          )
        end
      end
    end
  end
end
