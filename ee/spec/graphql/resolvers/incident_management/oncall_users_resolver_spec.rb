# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::IncidentManagement::OncallUsersResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:schedule) { create(:incident_management_oncall_schedule, :with_rotation, :utc) }
  let_it_be(:project) { schedule.project }

  let(:args) { {} }

  subject(:users) { sync(resolve_oncall_users(args)) }

  before do
    stub_licensed_features(oncall_schedules: true)
    project.add_reporter(current_user)
  end

  it 'returns on-call users' do
    expect(users.length).to eq(1)
    expect(users.first).to be_a(::User)
    expect(schedule.participants.pluck(:user_id)).to include(users.first.id)
  end

  it 'calls the finder with the execution_time context' do
    execution_time = Time.current
    context = { current_user: current_user, execution_time: execution_time }

    expect(::IncidentManagement::OncallUsersFinder).to receive(:new)
      .with(project, hash_including(oncall_at: execution_time))
      .and_call_original

    resolve_oncall_users({}, context)
  end

  context 'when an error occurs while finding shifts' do
    before do
      stub_licensed_features(oncall_schedules: false)
    end

    it 'returns no users' do
      expect(subject).to eq(::User.none)
    end
  end

  private

  def resolve_oncall_users(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: schedule, args: args, ctx: context)
  end
end
