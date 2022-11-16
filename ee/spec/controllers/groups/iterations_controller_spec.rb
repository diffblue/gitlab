# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::IterationsController, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:other_group) { create(:group, :private) }
  let_it_be(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group)) }
  let_it_be(:other_iteration) do
    create(:iteration, iterations_cadence: create(:iterations_cadence, group: other_group))
  end

  let_it_be(:user) { create(:user) }

  before do
    stub_licensed_features(iterations: iteration_license_available)

    group.send("add_#{role}", user) unless role == :none
    sign_in(user)
  end

  describe 'index' do
    subject { get :index, params: { group_id: group } }

    where(:iteration_license_available, :role) do
      false | :developer
      true  | :none
    end

    with_them do
      it_behaves_like 'returning response status', :not_found
    end

    where(:iteration_license_available, :role) do
      true  | :guest
      true  | :developer
    end

    with_them do
      it 'redirects to the group iteration cadence index path' do
        subject

        expect(response).to redirect_to(group_iteration_cadences_path(group))
      end
    end
  end

  describe 'show' do
    let(:requested_iteration) { iteration }

    subject { get :show, params: { group_id: group, id: requested_iteration.id } }

    where(:iteration_license_available, :role, :requested_iteration) do
      false | :developer | lazy { iteration }
      true  | :none      | lazy { iteration }
      true  | :guest     | lazy { other_iteration }
    end

    with_them do
      it_behaves_like 'returning response status', :not_found
    end

    context 'when current user can view the requested iteration' do
      where(:iteration_license_available, :role) do
        true  | :guest
        true  | :developer
      end

      with_them do
        it 'redirects to the corresponding iteration cadence path' do
          subject

          expect(response).to redirect_to(
            group_iteration_cadence_iteration_path(
              iteration_cadence_id: iteration.iterations_cadence_id,
              id: iteration.id
            )
          )
        end
      end
    end
  end

  describe 'new' do
    subject { get :new, params: { group_id: group } }

    where(:iteration_license_available, :role) do
      false | :developer
      true  | :none
      true  | :guest
    end

    with_them do
      it_behaves_like 'returning response status', :not_found
    end

    context 'when role is developer' do
      let(:iteration_license_available) { true }
      let(:role) { :developer }

      it 'redirects to the group iteration cadence index path' do
        subject

        expect(response).to redirect_to(group_iteration_cadences_path(group))
      end
    end
  end

  describe 'edit' do
    let(:requested_iteration) { iteration }

    subject { get :edit, params: { group_id: group, id: requested_iteration.id } }

    where(:iteration_license_available, :role, :requested_iteration) do
      false | :developer | lazy { iteration }
      true  | :none      | lazy { iteration }
      true  | :guest     | lazy { iteration }
      true  | :developer | lazy { other_iteration }
    end

    with_them do
      it_behaves_like 'returning response status', :not_found
    end

    context 'when role is developer and can edit the requested iteration' do
      let(:iteration_license_available) { true }
      let(:role) { :developer }

      it 'redirects to the corresponding iteration cadence path' do
        subject

        expect(response).to redirect_to(
          edit_group_iteration_cadence_iteration_path(
            iteration_cadence_id: requested_iteration.iterations_cadence_id,
            id: requested_iteration.id
          )
        )
      end
    end
  end
end
