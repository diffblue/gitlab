# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectMembersHelper do
  include OncallHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:current_user) { user }

  before do
    allow(helper).to receive(:current_user).and_return(current_user)
    allow(helper).to receive(:can?).and_return(true)
  end

  describe '#project_members_app_data_json' do
    before do
      project.add_developer(user)
      create_schedule_with_user(project, user)
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

      expect { call_project_members_app_data_json }.not_to exceed_query_limit(control_count).with_threshold(6) # existing n+1
    end
  end

  def call_project_members_app_data_json
    helper.project_members_app_data_json(project, members: preloaded_members, group_links: [], invited: [], access_requests: [])
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
