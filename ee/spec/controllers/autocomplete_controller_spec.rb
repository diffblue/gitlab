# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutocompleteController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }

  context 'GET users' do
    let_it_be(:user2) { create(:user) }
    let_it_be(:non_member) { create(:user) }

    context 'project members' do
      before do
        project.add_developer(user2)
        sign_in(user)
      end

      describe "GET #users that can push to protected branches" do
        before do
          get(:users, params: { project_id: project.id, push_code_to_protected_branches: 'true' })
        end

        it 'returns authorized users', :aggregate_failures do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(1)
          expect(json_response.map { |u| u["username"] }).to match_array([user.username])
        end
      end

      describe "GET #users that can push code" do
        let(:reporter_user) { create(:user) }

        before do
          project.add_reporter(reporter_user)
          get(:users, params: { project_id: project.id, push_code: 'true' })
        end

        it 'returns authorized users', :aggregate_failures do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(2)
          expect(json_response.map { |user| user["username"] }).to match_array([user.username, user2.username])
        end
      end

      describe "GET #users that can push to protected branches, including the current user" do
        before do
          get(:users, params: { project_id: project.id, push_code_to_protected_branches: true, current_user: true })
        end

        it 'returns authorized users', :aggregate_failures do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(1)
          expect(json_response.map { |u| u["username"] }).to match_array([user.username])
        end
      end
    end
  end

  context 'groups' do
    let_it_be(:public_group) { create(:group, :public) }
    let_it_be(:authorized_private_group) { create(:group, :private) }
    let_it_be(:unauthorized_private_group) { create(:group, :private) }
    let_it_be(:non_invited_group) { create(:group, :public) }

    before_all do
      authorized_private_group.add_guest(user)
      project.invited_groups = [public_group, authorized_private_group, unauthorized_private_group]
    end

    context "while fetching all groups belonging to a project" do
      before do
        sign_in(user)
        get(:project_groups, params: { project_id: project.id })
      end

      it 'returns groups invited to the project that the user can see' do
        expect(json_response).to contain_exactly(
          a_hash_including("id" => authorized_private_group.id),
          a_hash_including("id" => public_group.id)
        )
      end
    end

    context "while fetching all groups belonging to a project the current user cannot access" do
      let(:user2) { create(:user) }

      before do
        sign_in(user2)
        get(:project_groups, params: { project_id: project.id })
      end

      it { expect(response).to be_not_found }
    end

    context "while fetching all groups belonging to an invalid project ID" do
      before do
        sign_in(user)
        get(:project_groups, params: { project_id: non_existing_record_id })
      end

      it { expect(response).to be_not_found }
    end
  end

  shared_examples 'has expected results' do
    it 'returns the matching routes', :aggregate_failures do
      expect(json_response).to be_kind_of(Array)
      expect(json_response.size).to eq(expected_results.length)

      json_response.each do |result|
        expect(expected_results).to include(result.values_at('source_id', 'source_type'))
      end
    end
  end

  context 'GET project_routes' do
    let_it_be(:group) { create(:group) }
    let_it_be(:projects) { create_list(:project, 3, group: group) }

    before do
      sign_in(user)
      get(:project_routes, params: { search: search })
    end

    context 'as admin' do
      let_it_be(:user) { create(:admin) }

      describe "while searching for a project by namespace" do
        let(:search) { group.path }
        let!(:expected_results) { group.projects.map { |p| [p.id, 'Project'] }}

        include_examples 'has expected results'
      end

      describe "while searching for a project by path" do
        let(:search) { projects.first.path }
        let!(:expected_results) { [[projects.first.id, 'Project']] }

        include_examples 'has expected results'
      end
    end

    context 'as project owner' do
      let(:user) { project.owner }
      let!(:expected_results) { [[project.id, 'Project']] }

      context "while searching for a project by namespace" do
        let(:search) { user.namespace.path }

        include_examples 'has expected results'
      end

      context "while searching for a project by path" do
        let(:search) { project.path }

        include_examples 'has expected results'
      end
    end

    context 'while searching for nothing' do
      let(:search) { nil }
      let(:expected_results) { [] }

      include_examples 'has expected results'
    end
  end

  context 'GET namespace_routes' do
    let_it_be(:groups) { create_list(:group, 3, :private) }
    let_it_be(:users) { create_list(:user, 3) }

    before do
      sign_in(user)
      get(:namespace_routes, params: { search: search })
    end

    context 'as admin' do
      let_it_be(:user) { create(:admin) }

      describe "while searching for a namespace by group path" do
        let(:search) { 'group' }
        let!(:expected_results) do
          Group.all.map { |g| [g.id, 'Namespace'] }
        end

        include_examples 'has expected results'
      end

      describe "while searching for a namespace by user path" do
        let(:search) { 'user' }
        let!(:expected_results) do
          User.all.map { |u| [u.namespace.id, 'Namespace'] }
        end

        include_examples 'has expected results'
      end
    end

    context 'as a user' do
      let(:search) { user.namespace.path }

      context "while searching for a namespace by path" do
        let!(:expected_results) { [[user.namespace.id, 'Namespace']] }

        include_examples 'has expected results'
      end
    end

    context 'as group member' do
      let_it_be(:group_developer) do
        groups.first.add_developer(users.first)

        users.first
      end

      let(:search) { groups.first.path }
      let(:user) { group_developer }

      context "while searching for a namespace by path" do
        let!(:expected_results) { [[groups.first.id, 'Namespace']] }

        include_examples 'has expected results'
      end
    end

    context 'while searching for nothing' do
      let(:search) { nil }
      let(:expected_results) { [] }

      include_examples 'has expected results'
    end
  end
end
