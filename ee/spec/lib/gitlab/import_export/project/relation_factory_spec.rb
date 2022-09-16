# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::RelationFactory do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:group) { create(:group) }
  let(:created_object) do
    described_class.create( # rubocop:disable Rails/SaveBang
      relation_sym: relation_sym,
      relation_hash: relation_hash,
      relation_index: 1,
      members_mapper: instance_double('Gitlab::ImportExport::MembersMapper', map: {}),
      object_builder: Gitlab::ImportExport::Project::ObjectBuilder,
      user: user,
      importable: project,
      excluded_keys: []
    )
  end

  describe 'iteration' do
    let(:relation_sym) { :iteration }
    let(:relation_hash) do
      {
        'iid' => 1,
        'start_date' => '2022-01-01',
        'due_date' => '2022-02-02',
        'description' => 'iteration',
        'iterations_cadence' => {
          'title' => 'iterations cadence'
        }
      }
    end

    context 'when project has no group' do
      it 'does not create iteration' do
        expect(created_object).to be_nil
      end
    end
  end

  describe 'resource iteration events' do
    let(:relation_sym) { :resource_iteration_events }
    let(:relation_hash) do
      {
        'user_id' => 1,
        'created_at' => '2022-08-17T13:04:02.495Z',
        'action' => 'add',
        'iteration' => nil
      }
    end

    context 'when iteration object has no iteration associated' do
      let(:project) { create(:project, group: group) }

      it 'does not create resource iteration event' do
        expect(created_object).to be_nil
      end
    end

    context 'when project has no group' do
      it 'does not create resource iteration event' do
        expect(created_object).to be_nil
      end
    end
  end
end
