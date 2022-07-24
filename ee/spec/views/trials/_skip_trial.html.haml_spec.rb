# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'trials/_skip_trial.html.haml' do
  include ApplicationHelper

  let(:source) { nil }

  before do
    params[:glm_source] = source
    render 'trials/skip_trial'
  end

  subject { rendered }

  shared_examples 'has Skip Trial verbiage' do
    it { is_expected.to have_content("Skip Trial") }
  end

  context 'without glm_source' do
    include_examples 'has Skip Trial verbiage'
  end

  context 'with glm_source of about.gitlab.com' do
    let(:source) { 'about.gitlab.com' }

    include_examples 'has Skip Trial verbiage'
  end

  context 'with glm_source of gitlab.com' do
    let(:source) { Gitlab.config.gitlab.host }

    it { is_expected.to have_content("Go back to GitLab") }
  end
end
