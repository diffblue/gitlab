# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::IncidentManagement::OncallShiftsResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:rotation) { create(:incident_management_oncall_rotation, :with_participants, :utc) }
  let_it_be(:project) { rotation.project }

  let(:args) { { start_time: rotation.starts_at, end_time: rotation.starts_at + rotation.shift_cycle_duration } }

  subject(:shifts) { sync(resolve_oncall_shifts(args).to_a) }

  before do
    stub_licensed_features(oncall_schedules: true)
    project.add_reporter(current_user)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::IncidentManagement::OncallShiftType.connection_type)
  end

  it 'returns on-call schedules' do
    expect(shifts.length).to eq(1)
    expect(shifts.first).to be_a(::IncidentManagement::OncallShift)
    expect(shifts.first).to have_attributes(rotation: rotation, starts_at: args[:start_time], ends_at: args[:end_time])
  end

  context 'when an error occurs while finding shifts' do
    subject(:shifts) { sync(resolve_oncall_shifts(args, current_user: nil)) }

    it 'generates a ResourceNotAvailable error' do
      expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
        subject
      end
    end
  end

  private

  def resolve_oncall_shifts(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: rotation, args: args, ctx: context)
  end
end
