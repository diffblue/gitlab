# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceIterationEventPolicy, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:private_project) { create(:project, :private, group: private_group) }

  describe '#read_resource_iteration_event' do
    context 'with non-member user' do
      it 'does not allow to read event' do
        event = build_event(project)

        expect(permissions(user, event)).to be_disallowed(:read_resource_iteration_event, :read_note)
      end
    end

    context 'with member user' do
      before do
        project.add_guest(user)
      end

      it 'allows to read event for accessible iteration' do
        event = build_event(project)

        expect(permissions(user, event)).to be_allowed(:read_resource_iteration_event, :read_note)
      end

      it 'does not allow to read event for not accessible iteration' do
        event = build_event(private_project)

        expect(permissions(user, event)).to be_disallowed(:read_resource_iteration_event, :read_note)
      end
    end
  end

  describe '#read_iteration' do
    before do
      project.add_guest(user)
    end

    it 'allows to read deleted iteration' do
      event = build(:resource_iteration_event, issue: issue, iteration: nil)

      expect(permissions(user, event)).to be_allowed(:read_iteration, :read_resource_iteration_event, :read_note)
    end

    it 'allows to read accessible iteration' do
      event = build_event(project)

      expect(permissions(user, event)).to be_allowed(:read_iteration, :read_resource_iteration_event, :read_note)
    end

    it 'does not allow to read not accessible iteration' do
      event = build_event(private_project)

      expect(permissions(user, event)).to be_disallowed(:read_iteration, :read_resource_iteration_event, :read_note)
    end
  end

  def build_event(project)
    iteration = create(:iteration, group: project.group)

    build(:resource_iteration_event, issue: issue, iteration: iteration)
  end

  def permissions(user, issue)
    described_class.new(user, issue)
  end
end
