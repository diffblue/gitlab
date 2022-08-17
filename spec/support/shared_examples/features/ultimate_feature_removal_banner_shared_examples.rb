# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "ultimate feature removal banner" do
  context 'when it should show the banner', :saas do
    before(:all) do
      project = create(:project, :public)
      user = create(:user)
      stub_feature_flags(ultimate_feature_removal_banner: true)
      project.add_guest(user)
      project.project_setting.update!(legacy_open_source_license_available: false)
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
