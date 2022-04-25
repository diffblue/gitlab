# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IterationsController do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  shared_examples 'iterations license is not available' do
    before do
      stub_licensed_features(iterations: false)
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

      context 'when iteration cadences is disabled' do
        before do
          stub_feature_flags(iteration_cadences: false)
        end

        it_behaves_like 'returning response status', :success
      end
    end
  end

  describe 'show' do
    let_it_be(:cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:iteration) { create(:iteration, iterations_cadence: cadence) }

    let(:requested_iteration) { iteration }

    subject do
      get :show,
      params: {
        namespace_id: project.namespace,
        project_id: project,
        id: requested_iteration.id
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

      context 'when iteration cadences is disabled' do
        before do
          stub_feature_flags(iteration_cadences: false)
        end

        it_behaves_like 'returning response status', :success
      end
    end
  end
end
