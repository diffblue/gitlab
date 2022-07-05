# frozen_string_literal: true

RSpec.shared_examples 'accessing iteration cadences' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:cadence) { create(:iterations_cadence, group: group) }
  let_it_be(:user) { create(:user) }

  before do
    stub_feature_flags(iteration_cadences: feature_flag_available)
    group.add_member(user, role) unless role == :none
    sign_in(user)
  end

  describe 'index' do
    where(:feature_flag_available, :role, :status) do
      false | :developer | :not_found
      true  | :none      | :not_found
      true  | :guest     | :success
      true  | :developer | :success
    end

    with_them do
      it_behaves_like 'returning response status', params[:status]
    end
  end
end
