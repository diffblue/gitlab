# frozen_string_literal: true

class SurveyResponsesController < ApplicationController
  SURVEY_RESPONSE_SCHEMA_URL = 'iglu:com.gitlab/survey_response/jsonschema/1-0-1'
  CALENDLY_INVITE_LINK = 'https://calendly.com/d/n9wd-sy2b/gitlab-user-onboarding-research'

  before_action :track_response, only: :index
  before_action :set_invite_link, only: :index
  before_action :set_show_incentive, only: :index

  skip_before_action :authenticate_user!

  feature_category :navigation

  def index
    render layout: false
  end

  private

  def track_response
    return unless Gitlab.com?

    data = {
      survey_id: to_number(params[:survey_id]),
      instance_id: to_number(params[:instance_id]),
      user_id: to_number(params[:user_id]),
      email: params[:email],
      name: params[:name],
      username: params[:username],
      response: params[:response],
      onboarding_progress: to_number(params[:onboarding_progress])
    }.compact

    context = SnowplowTracker::SelfDescribingJson.new(SURVEY_RESPONSE_SCHEMA_URL, data)

    ::Gitlab::Tracking.event(self.class.name, 'submit_response', context: [context])
  end

  def to_number(param)
    param.to_i if param&.match?(/^\d+$/)
  end

  def set_invite_link
    return unless Gitlab.com?
    return unless Gitlab::Utils.to_boolean(params[:show_invite_link])
    return unless Feature.enabled?(:calendly_invite_link)

    @invite_link = CALENDLY_INVITE_LINK
  end

  def set_show_incentive
    return unless @invite_link

    @show_incentive = Gitlab::Utils.to_boolean(params[:show_incentive])
  end
end
