# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CodeOwners::GroupsLoader, feature_category: :source_code_management do
  let(:text) do
    <<~TXT
    This is a long text that mentions some groups.
    @group-1 and @group-doesnt-exist take a walk in the park.
    There they meet @group-2 and @group-1/with-nested/Group-3
    TXT
  end

  let(:extractor) { Gitlab::CodeOwners::ReferenceExtractor.new(text) }
  let(:project) { create(:project, :public) }
  let(:entry) { double('Entries') }

  describe '#load_to' do
    subject(:load_groups) do
      described_class.new(project, extractor).load_to([entry])
    end

    before do
      allow(entry).to receive(:add_matching_groups_from)
    end

    context 'input has no matching group paths' do
      let(:text) { 'My test' }

      it 'returns an empty list of groups' do
        load_groups

        expect(entry).to have_received(:add_matching_groups_from).with([])
      end
    end

    context 'nil input' do
      let(:text) { nil }

      it 'returns an empty relation when nil was passed' do
        load_groups

        expect(entry).to have_received(:add_matching_groups_from).with([])
      end
    end

    context 'input matches group paths' do
      let(:project) { create(:project, :private) }

      it 'returns the groups case insensitive for names' do
        group = create(:group, path: "GROUP-1")
        create(:group, path: "GROUP-2")
        project.invited_groups << group

        load_groups

        expect(entry).to have_received(:add_matching_groups_from).with([group])
      end
    end

    context "input matches project.group" do
      let(:group) { create(:group) }
      let(:project) { create(:project, :repository, namespace: group) }
      let(:text) { "@#{project.group.full_path}" }

      it "returns the project's group" do
        load_groups

        expect(entry).to have_received(:add_matching_groups_from).with([group])
      end
    end

    context 'input as array of strings' do
      let(:text) { super().lines }

      it 'is treated as one string' do
        group_1 = create(:group, path: 'GROup-1')
        group_2 = create(:group, path: 'GROUP-2')
        create(:group, path: 'group-3')
        project.invited_groups << [group_1, group_2]

        load_groups

        expect(entry).to have_received(:add_matching_groups_from) do |args|
          expect(args).to contain_exactly(group_2, group_1)
        end
      end
    end

    context 'nested groups' do
      it 'returns nested groups by mentioned full paths' do
        group_1 = create(:group, path: 'GROup-1')
        group_2 = create(:group, path: 'with-nested', parent: group_1)
        create(:group, path: 'not-invited')
        nested_group = create(:group, path: 'group-3', parent: group_2)
        project.invited_groups << [group_1, group_2, nested_group]

        load_groups

        expect(entry).to have_received(:add_matching_groups_from) do |args|
          expect(args).to contain_exactly(group_1, nested_group)
        end
      end
    end
  end
end
