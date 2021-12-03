# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Group::RelationFactory do
  let(:group) { create(:group) }
  let(:members_mapper) { double('members_mapper').as_null_object }
  let(:admin) { create(:admin) }
  let(:importer_user) { admin }
  let(:excluded_keys) { [] }
  let(:created_object) do
    described_class.create( # rubocop:disable Rails/SaveBang
      relation_sym: relation_sym,
      relation_hash: relation_hash,
      relation_index: 1,
      members_mapper: members_mapper,
      object_builder: Gitlab::ImportExport::Group::ObjectBuilder,
      user: importer_user,
      importable: group,
      excluded_keys: excluded_keys
    )
  end

  context 'epic object' do
    let(:relation_sym) { :epics }
    let(:id) { random_id }
    let(:original_group_id) { random_id }

    let(:relation_hash) do
      {
        'id' => id,
        'milestone_id' => nil,
        'group_id' => original_group_id,
        'assignee_id' => nil,
        'created_at' => 'Wed, 20 Nov 2019 11:02:24 UTC +00:00',
        'updated_at' => 'Wed, 20 Nov 2019 11:02:24 UTC +00:00',
        'title' => 'Title',
        'description' => 'Description',
        'state_id' => 'opened'
      }
    end

    it 'does not have the original ID' do
      expect(created_object.id).not_to eq(id)
    end

    it 'does not have the original group_id' do
      expect(created_object.group_id).not_to eq(original_group_id)
    end

    it 'has the new group_id' do
      expect(created_object.group_id).to eq(group.id)
    end

    context 'excluded attributes' do
      let(:excluded_keys) { %w[description] }

      it 'are removed from the imported object' do
        expect(created_object.description).to be_nil
      end
    end

    context 'overridden model' do
      let(:relation_sym) { :parent }

      it 'does not raise errors' do
        expect { created_object }.not_to raise_error
      end
    end
  end

  it_behaves_like 'Notes user references' do
    let(:importable) { group }
    let(:relation_hash) do
      {
        'id' => 4947,
        'note' => 'note',
        'noteable_type' => 'Epic',
        'author_id' => 999,
        'created_at' => '2016-11-18T09:29:42.634Z',
        'updated_at' => '2016-11-18T09:29:42.634Z',
        'project_id' => 1,
        'attachment' => {
          'url' => nil
        },
        'noteable_id' => 377,
        'system' => true,
        'author' => {
          'name' => 'Administrator'
        },
        'events' => []
      }
    end
  end

  def random_id
    rand(10_000..100_000)
  end
end
