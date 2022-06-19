# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resolvers::IncidentManagement::OncallRotationsResolver' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:rotation) { create(:incident_management_oncall_rotation, :with_participants, :utc) }
  let_it_be(:second_rotation) { create(:incident_management_oncall_rotation, :with_participants, :utc, schedule: rotation.schedule) }
  let_it_be(:schedule) { rotation.schedule }
  let_it_be(:project) { rotation.project }
  let_it_be(:described_class) { Resolvers::IncidentManagement::OncallRotationsResolver }

  let(:args) { {} }
  let(:resolver) { described_class }

  subject(:resolved_rotations) { sync(resolve_oncall_rotations(args, current_user: current_user).to_a) }

  before do
    stub_licensed_features(oncall_schedules: true)
    project.add_reporter(current_user)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::IncidentManagement::OncallRotationType.connection_type)
  end

  it 'returns on-call rotations' do
    expect(resolved_rotations.length).to eq(2)
    expect(resolved_rotations.first).to be_a(::IncidentManagement::OncallRotation)
    expect(resolved_rotations.first).to have_attributes(id: second_rotation.id)
    expect(resolved_rotations.last).to have_attributes(id: rotation.id)
  end

  context 'when user does not have permissions' do
    let(:another_user) { create(:user) }

    subject(:resolved_rotations) { sync(resolve_oncall_rotations(args, current_user: another_user).to_a) }

    it 'returns no rotations' do
      expect(resolved_rotations.length).to eq(0)
    end
  end

  context 'when resolving a single item' do
    let(:resolver) { described_class.single }

    subject(:resolved_rotation) { sync(resolve_oncall_rotations(args, current_user: current_user)) }

    context 'when id given' do
      let(:args) { { id: rotation.to_global_id } }

      it 'returns the on-call rotation' do
        expect(resolved_rotation).to eq(rotation)
      end
    end
  end

  private

  def resolve_oncall_rotations(args = {}, context = { current_user: current_user })
    resolve(resolver, obj: schedule, args: args, ctx: context)
  end
end
