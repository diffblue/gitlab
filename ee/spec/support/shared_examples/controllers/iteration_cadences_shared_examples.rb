# frozen_string_literal: true

RSpec.shared_examples 'accessing iteration cadences' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:cadence) { create(:iterations_cadence, group: group) }
  let_it_be(:user) { create(:user) }

  before do
    group.add_member(user, role) unless role == :none
    sign_in(user)
  end

  describe 'index' do
    where(:role, :status) do
      :none      | :not_found
      :guest     | :success
      :developer | :success
    end

    with_them do
      it_behaves_like 'returning response status', params[:status]
    end
  end
end
