# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::ObjectBuilder do
  let!(:group) { create(:group, :private) }
  let!(:subgroup) { create(:group, :private, parent: group) }
  let!(:project) do
    create(:project, :repository,
           :builds_disabled,
           :issues_disabled,
           name: 'project',
           path: 'project',
           group: subgroup)
  end

  context 'epics' do
    it 'finds the existing epic' do
      epic = create(:epic, title: 'epic', group: project.group)

      expect(described_class.build(Epic,
                                   'iid' => 1,
                                   'title' => 'epic',
                                   'group' => project.group,
                                   'author_id' => project.creator.id)).to eq(epic)
    end

    it 'finds the existing epic in root ancestor' do
      epic = create(:epic, title: 'epic', group: group)

      expect(described_class.build(Epic,
                                   'iid' => 1,
                                   'title' => 'epic',
                                   'group' => project.group,
                                   'author_id' => project.creator.id)).to eq(epic)
    end

    it 'creates a new epic' do
      epic = described_class.build(Epic,
                                   'iid' => 1,
                                   'title' => 'epic',
                                   'group' => project.group,
                                   'author_id' => project.creator.id)

      expect(epic.persisted?).to be true
    end
  end

  context 'iterations' do
    it 'finds existing iteration based on iterations cadence title' do
      cadence = create(:iterations_cadence, title: 'iterations cadence', group: project.group)
      iteration = create(
        :iteration,
        iid: 2,
        start_date: '2022-01-01',
        due_date: '2022-02-02',
        group: project.group,
        iterations_cadence: cadence
      )

      object = described_class.build(
        Iteration,
        {
          'iid' => 2,
          'start_date' => '2022-01-01',
          'due_date' => '2022-02-02',
          'iterations_cadence' => cadence,
          'group' => project.group
        }
      )

      expect(object).to eq(iteration)
    end

    context 'when existing iteration does not exist' do
      it 'does not create a new iteration' do
        expect(described_class.build(Iteration,
                                     'iid' => 2,
                                     'start_date' => '2022-01-01',
                                     'due_date' => '2022-02-02',
                                     'group' => project.group)).to eq(nil)
      end
    end
  end
end
