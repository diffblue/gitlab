# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "ultimate feature removal banner" do
  include EE::ProjectsHelper

  context 'when it should show the banner', :saas do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public) }

    before do
      stub_feature_flags(ultimate_feature_removal_banner: true)
      project.add_guest(user)
      allow(EE::ProjectsHelper).to receive(:user_dismissed?).with(Users::CalloutsHelper::ULTIMATE_FEATURE_REMOVAL_BANNER).and_return(false)
      allow(project.project_setting).to receive(:legacy_open_source_license_available).and_return(false)
    end

    it "shows the banner message" do
      expect(page).to have_content("Your project is no longer receiving GitLab Ultimate benefits as of 2022-07-01.")
    end

    it "has a link to the FAQ" do
      faq_link = 'https://about.gitlab.com/pricing/faq-efficient-free-tier/#public-projects-on-gitlab-saas-free-tier'
      expect(page).to have_link('FAQ', href: faq_link)
    end
  end
end
