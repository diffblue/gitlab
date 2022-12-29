# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::ReleaseCreatedAuditEventService do
  describe '#security_event' do
    context 'with no milestones' do
      include_examples 'logs the release audit event' do
        let(:release) { create(:release, project: entity) }
        let(:custom_message) { "Created Release #{release.tag}" }
      end
    end

    context "with one milestone" do
      include_examples 'logs the release audit event' do
        let(:release) { create(:release, :with_milestones, milestones_count: 1, project: entity) }
        let(:custom_message) { "Created Release #{release.tag} with Milestone #{Milestone.first.title}" }
      end
    end

    context "with multiple milestones" do
      include_examples 'logs the release audit event' do
        let(:release) { create(:release, :with_milestones, milestones_count: 2, project: entity) }
        let(:custom_message) { "Created Release #{release.tag} with Milestones #{Milestone.order_by_dates_and_title.first.title}, #{Milestone.order_by_dates_and_title.second.title}" }
      end
    end
  end
end
