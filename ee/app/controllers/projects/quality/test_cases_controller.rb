# frozen_string_literal: true

class Projects::Quality::TestCasesController < Projects::ApplicationController
  prepend_before_action :authenticate_user!, only: [:new]

  before_action :check_quality_management_available!
  before_action :authorize_read_issue!
  before_action :authorize_create_test_case!, only: [:new]

  feature_category :quality_management
  urgency :low, [:index]
  urgency :default, [:new, :show]

  def index
    respond_to do |format|
      format.html
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def show
    @test_case = test_cases_finder
                  .execute
                  .iid_in(params[:id])
                  .without_order
                  .take! # rubocop: disable CodeReuse/ActiveRecord

    serializer = IssueSerializer.new(current_user: current_user, project: project)

    @issuable_sidebar = serializer.represent(@test_case, serializer: 'sidebar')

    respond_to do |format|
      format.html
    end
  end

  private

  def test_cases_finder
    IssuesFinder.new(current_user, project_id: project.id, issue_types: :test_case)
  end
end
