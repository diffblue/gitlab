# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'trial_registrations/new.html.haml' do
  let_it_be(:resource) { Users::AuthorizedBuildService.new(nil, {}).execute }

  before do
    allow(view).to receive(:arkose_labs_enabled?).and_return(false)
    allow(view).to receive(:resource).and_return(resource)
    allow(view).to receive(:resource_name).and_return(:user)
    allow(view).to receive(:glm_tracking_params).and_return({})
  end

  subject { render && rendered }

  it { is_expected.not_to have_content(_('Start a Free Ultimate Trial')) }
  it { is_expected.to have_content(s_('InProductMarketing|Free 30-day trial')) }
  it { is_expected.to have_content(s_('InProductMarketing|No credit card required.')) }
  it { is_expected.to have_selector('img[alt$=" logo"]') }

  it { is_expected.to have_content(s_('InProductMarketing|Want to host GitLab on your servers?')) }
  it { is_expected.to have_link(s_('InProductMarketing|Start a Self-Managed trial'), href: 'https://about.gitlab.com/free-trial/#selfmanaged/') }
end
