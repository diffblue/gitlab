# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::WithAccessCheck do
  let_it_be(:ancestor) { create(:group) }
  let_it_be(:group) { create(:group, parent: ancestor) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:other_group) { create(:group, :private) }
  let_it_be(:parent_epic) { create(:epic, group: group) }
  let_it_be(:group_epic) { create(:epic, group: group, parent: parent_epic) }
  let_it_be(:confidential_epic) { create(:epic, :confidential, group: group, parent: parent_epic) }
  let_it_be(:ancestor_child_epic) { create(:epic, group: ancestor, parent: parent_epic) }
  let_it_be(:subgroup_child_epic) { create(:epic, group: subgroup, parent: parent_epic) }
  let_it_be(:other_child_epic) { create(:epic, group: other_group, parent: parent_epic) }

  let_it_be(:user) { create(:user) }
  let(:params) { { parent: parent_epic } }

  let(:finder_class) do
    Class.new do
      include Epics::WithAccessCheck

      attr_reader :current_user, :params

      def initialize(current_user, params = {})
        @current_user = current_user
        @params = params
      end

      def execute
        epics_with_read_access
      end

      def epics_collection
        Epic.in_parents(base_epic)
      end
      alias_method :epics_collection_for_groups, :epics_collection

      def base_epic
        params[:parent]
      end
    end
  end

  before do
    stub_licensed_features(epics: true)
  end

  context 'when required methods are not implemented' do
    let(:dummy_class) do
      Class.new do
        include Epics::WithAccessCheck

        attr_reader :current_user, :params

        def initialize(current_user, params = {})
          @current_user = current_user
          @params = params
        end

        def execute
          epics_with_read_access
        end
      end
    end

    context 'when `epics_collection` is not defined in inheriting class' do
      before do
        stub_const('DummyFinder', dummy_class)

        DummyFinder.class_eval do
          def base_epic
            params[:parent]
          end
        end
      end

      it 'raises NotImplementedError' do
        expect { DummyFinder.new(user, params).execute }.to raise_error(NotImplementedError)
      end
    end

    context 'when `base_epic` is not defined in inheriting class' do
      let(:params) { { include_descendant_groups: false } }

      before do
        stub_const('DummyFinder', dummy_class)

        DummyFinder.class_eval do
          def epics_collection
            Epic.all
          end
        end
      end

      it 'raises NotImplementedError' do
        expect { DummyFinder.new(user, params).execute }.to raise_error(NotImplementedError)
      end
    end
  end

  context "when user is not authenticated" do
    let(:user) { nil }

    it 'returns only epics with public access' do
      finder = finder_class.new(user, params)

      expect(finder.execute).to match_array(
        [
          group_epic,
          ancestor_child_epic,
          subgroup_child_epic
        ])
    end
  end

  context "when user has guest access to base epic's group" do
    before do
      group.add_guest(user)
    end

    it 'returns only visible epics' do
      finder = finder_class.new(user, params)

      expect(finder.execute).to match_array(
        [
          group_epic,
          ancestor_child_epic,
          subgroup_child_epic
        ])
    end
  end

  context "when user has reporter access to base epic's group" do
    before do
      group.add_reporter(user)
    end

    it 'returns only visible epics' do
      finder = finder_class.new(user, params)

      expect(finder.execute).to match_array(
        [
          group_epic,
          confidential_epic,
          ancestor_child_epic,
          subgroup_child_epic
        ])
    end

    context 'when param include_ancestor_groups is false' do
      let(:params) { { parent: parent_epic, include_ancestor_groups: false } }

      it 'excludes epics from ancestor groups' do
        finder = finder_class.new(user, params)

        expect(finder.execute).to match_array(
          [
            group_epic,
            confidential_epic,
            subgroup_child_epic
          ])
      end
    end

    context 'when param include_descendant_groups is false' do
      let(:params) { { parent: parent_epic, include_descendant_groups: false } }

      it 'excludes epics from descendant groups' do
        finder = finder_class.new(user, params)

        expect(finder.execute).to match_array(
          [
            group_epic,
            confidential_epic,
            ancestor_child_epic
          ])
      end
    end
  end

  context "when user has reporter access to all groups" do
    before do
      group.add_reporter(user)
      other_group.add_reporter(user)
    end

    it 'returns only visible epics' do
      finder = finder_class.new(user, params)

      expect(finder.execute).to match_array(
        [
          group_epic,
          confidential_epic,
          ancestor_child_epic,
          subgroup_child_epic,
          other_child_epic
        ])
    end
  end
end
