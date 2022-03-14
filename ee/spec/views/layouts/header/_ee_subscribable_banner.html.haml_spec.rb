# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/header/_ee_subscribable_banner' do
  let(:group) { build(:group) }
  let(:project_namespace) { build(:group) }
  let(:project) { build(:project, namespace: project_namespace) }
  let(:message) { double(:message) }

  before do
    allow(view).to receive(:gitlab_subscription_or_license).and_return(license)
    allow(view).to receive(:gitlab_subscription_message_or_license_message).and_return(message)
  end

  shared_examples 'displays the correct link' do
    context "when license is expiring" do
      let(:license) { build(:gitlab_license, expires_at: Date.current + 1.week) }

      it 'shows both renew and dismiss links' do
        expect(rendered).to have_link 'Renew subscription', href: view.renew_subscription_path
        expect(rendered).to have_button "That's OK, I don't want to renew"
      end
    end

    context "when license has expired" do
      let(:license) { build(:gitlab_license, expires_at: Date.current - 1.week) }

      it 'shows the upgrade plan link' do
        expect(rendered).to have_link 'Renew subscription', href: view.upgrade_subscription_path
      end
    end

    context "when license blocks changes" do
      let(:license) { build(:gitlab_license, expires_at: Date.current - 3.weeks) }

      it 'shows the renew plan link' do
        expect(rendered).to have_link 'Renew subscription', href: view.renew_subscription_path
      end
    end
  end

  context 'with a group' do
    before do
      assign(:group, group)
      render
    end

    it_behaves_like 'displays the correct link' do
      let(:namespace) { group }
    end
  end

  context 'with a project' do
    before do
      assign(:project, project)
      render
    end

    it_behaves_like 'displays the correct link' do
      let(:namespace) { project.namespace }
    end
  end

  context 'with both a group and a project' do
    before do
      assign(:group, group)
      assign(:project, project)
      render
    end

    it_behaves_like 'displays the correct link' do
      let(:namespace) { project.namespace }
    end
  end
end
