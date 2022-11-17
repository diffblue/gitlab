# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectMembersHelper do
  include OncallHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(current_user)
  end

  describe '#project_members_app_data_json' do
    before do
      project.add_developer(current_user)
      create_schedule_with_user(project, current_user)
      allow(helper).to receive(:can_admin_project_member?).and_return(true)
      allow(helper).to receive(:can?).and_return(true)
    end

    it 'does not execute N+1' do
      control_count = ActiveRecord::QueryRecorder.new do
        call_project_members_app_data_json
      end.count

      expect(project.members.count).to eq(2)

      user_2 = create(:user)
      project.add_developer(user_2)
      create_schedule_with_user(project, user_2)

      expect(project.members.count).to eq(3)

      expect { call_project_members_app_data_json }.not_to exceed_query_limit(control_count).with_threshold(11) # existing n+1
    end

    def call_project_members_app_data_json
      helper.project_members_app_data_json(
        project,
        members: preloaded_members,
        invited: [],
        access_requests: [],
        include_relations: [:inherited, :direct],
        search: nil
      )
    end

    # Simulates the behaviour in ProjectMembersController
    def preloaded_members
      klass = Class.new do
        include MembersPresentation

        def initialize(user)
          @current_user = user
        end

        attr_reader :current_user
      end

      klass.new(current_user).present_members(project.members.reload)
    end
  end

  describe '#project_member_header_subtext' do
    let(:base_subtext) { "You can invite a new member to <strong>#{current_project.name}</strong> or invite another group." }
    let(:standard_subtext) { "^#{base_subtext}$" }
    let(:enforcement_subtext) { "^#{base_subtext}<br />To manage seats for all members" }

    let_it_be(:project_with_group) { create(:project, group: create(:group)) }

    where(:can_admin_member, :enforce_free_user_cap, :subtext, :current_project) do
      true  | true  | ref(:standard_subtext) | ref(:project)
      true  | true  | ref(:enforcement_subtext) | ref(:project_with_group)
      true  | false | ref(:standard_subtext) | ref(:project_with_group)
      false | true  | ref(:standard_subtext) | ref(:project_with_group)
      false | false | ref(:standard_subtext) | ref(:project_with_group)
    end

    before do
      assign(:project, current_project)
      allow(helper).to receive(:can?).with(current_user, :admin_project_member, current_project).and_return(true)
      allow(helper).to receive(:can?).with(current_user, :admin_group_member, current_project.root_ancestor)
                                     .and_return(can_admin_member)
      allow(::Namespaces::FreeUserCap).to receive(:notification_or_enforcement_enabled?)
                                            .with(current_project.root_ancestor).and_return(enforce_free_user_cap)
    end

    with_them do
      it 'contains expected text' do
        expect(helper.project_member_header_subtext(current_project)).to match(subtext)
      end
    end
  end
end
