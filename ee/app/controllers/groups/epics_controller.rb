# frozen_string_literal: true

class Groups::EpicsController < Groups::ApplicationController
  include IssuableActions
  include IssuableCollections
  include ToggleAwardEmoji
  include ToggleSubscriptionAction
  include EpicsActions
  include DescriptionDiffActions
  include ::Observability::ContentSecurityPolicy

  before_action :check_epics_available!
  before_action :epic, except: [:index, :create, :new, :bulk_update]
  before_action :authorize_update_issuable!, only: :update
  before_action :authorize_create_epic!, only: [:create, :new]
  before_action :verify_group_bulk_edit_enabled!, only: [:bulk_update]
  before_action :set_summarize_notes_feature_flag, only: :show
  after_action :log_epic_show, only: :show

  before_action do
    push_frontend_feature_flag(:epic_color_highlight, @group)
    push_frontend_feature_flag(:preserve_unchanged_markdown, @group)
    push_frontend_feature_flag(:content_editor_on_issues, @group)
    push_frontend_feature_flag(:moved_mr_sidebar, @project)
    push_frontend_feature_flag(:or_issuable_queries, @group)
    push_frontend_feature_flag(:saved_replies, current_user)
  end

  feature_category :portfolio_management
  urgency :default, [:show, :new, :realtime_changes]
  urgency :low, [:discussions]

  def new
    @noteable = Epic.new
  end

  def create
    @epic = ::Epics::CreateService.new(group: @group, current_user: current_user, params: epic_params).execute

    if @epic.persisted?
      render json: {
        web_url: group_epic_path(@group, @epic)
      }
    else
      head :unprocessable_entity
    end
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def epic
    @issuable = @epic ||= @group.epics.find_by(iid: params[:epic_id] || params[:id])

    return render_404 unless can?(current_user, :read_epic, @epic)

    @noteable = @epic
  end
  # rubocop: enable CodeReuse/ActiveRecord
  alias_method :issuable, :epic
  alias_method :awardable, :epic
  alias_method :subscribable_resource, :epic

  def subscribable_project
    nil
  end

  def epic_params
    params.require(:epic).permit(*epic_params_attributes)
  end

  def epic_params_attributes
    [
      :color,
      :title,
      :description,
      :start_date_fixed,
      :start_date_is_fixed,
      :due_date_fixed,
      :due_date_is_fixed,
      :state_event,
      :confidential,
      label_ids: [],
      update_task: [:index, :checked, :line_number, :line_source]
    ]
  end

  def serializer
    EpicSerializer.new(current_user: current_user)
  end

  def discussion_serializer
    DiscussionSerializer.new(project: nil, noteable: issuable, current_user: current_user, note_entity: EpicNoteEntity)
  end

  def update_service
    ::Epics::UpdateService.new(group: @group, current_user: current_user, params: epic_params.to_h)
  end

  def finder_type
    EpicsFinder
  end

  def sorting_field
    :epics_sort
  end

  def log_epic_show
    return unless current_user && @epic

    ::Gitlab::Search::RecentEpics.new(user: current_user).log_view(@epic)
  end

  def authorize_create_epic!
    return render_404 unless can?(current_user, :create_epic, group)
  end

  def verify_group_bulk_edit_enabled!
    render_404 unless group.licensed_feature_available?(:group_bulk_edit)
  end

  def set_summarize_notes_feature_flag
    push_force_frontend_feature_flag(:summarize_comments, can?(current_user, :summarize_notes, epic))
  end
end
