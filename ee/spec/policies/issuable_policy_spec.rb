# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuablePolicy, models: true do
  let_it_be(:non_member) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }

  let(:guest_issue) { create(:issue, project: project, author: guest) }
  let(:reporter_issue) { create(:issue, project: project, author: reporter) }

  before do
    project.add_guest(guest)
    project.add_reporter(reporter)
    project.add_developer(developer)

    allow(::Gitlab::IncidentManagement).to receive(:timeline_events_available?).with(project).and_return(true)
  end

  def permissions(user, issue)
    described_class.new(user, issue)
  end

  describe '#rules' do
    context 'in a public project' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:issue) { create(:issue, project: project) }

      it 'disallows non-members from creating and deleting metric images' do
        expect(permissions(non_member, issue)).to be_allowed(:read_issuable_metric_image)
        expect(permissions(non_member, issue)).to be_disallowed(:upload_issuable_metric_image, :update_issuable_metric_image, :destroy_issuable_metric_image)
      end

      it 'allows guests to read, create metric images, and delete them in their own issues' do
        expect(permissions(guest, issue)).to be_allowed(:read_issuable_metric_image)
        expect(permissions(guest, issue)).to be_disallowed(:upload_issuable_metric_image, :destroy_issuable_metric_image)

        expect(permissions(guest, guest_issue)).to be_allowed(:read_issuable_metric_image, :upload_issuable_metric_image, :update_issuable_metric_image, :destroy_issuable_metric_image)
      end

      it 'allows reporters to create and delete metric images' do
        expect(permissions(reporter, issue)).to be_allowed(:read_issuable_metric_image, :upload_issuable_metric_image, :update_issuable_metric_image, :destroy_issuable_metric_image)
        expect(permissions(reporter, reporter_issue)).to be_allowed(:read_issuable_metric_image, :upload_issuable_metric_image, :update_issuable_metric_image, :destroy_issuable_metric_image)
      end

      context 'Timeline events' do
        it 'allows non-members to read time line events' do
          expect(permissions(guest, issue)).to be_allowed(:read_incident_management_timeline_event)
        end

        it 'disallows reporters from managing timeline events' do
          expect(permissions(reporter, issue)).to be_disallowed(:admin_incident_management_timeline_event)
        end

        it 'allows developers to manage timeline events' do
          expect(permissions(developer, issue)).to be_allowed(:admin_incident_management_timeline_event)
        end

        context 'when timeline events are not available' do
          before do
            allow(::Gitlab::IncidentManagement).to receive(:timeline_events_available?).with(project).and_return(false)
          end

          it 'disallows guests from reading timeline events' do
            expect(permissions(guest, issue)).to be_disallowed(:read_incident_management_timeline_event)
          end

          it 'disallows developers from managing timeline events' do
            expect(permissions(developer, issue)).to be_disallowed(:admin_incident_management_timeline_event)
          end
        end
      end
    end

    context 'in a private project' do
      let_it_be(:project) { create(:project, :private) }
      let_it_be(:issue) { create(:issue, project: project) }

      it 'disallows non-members from creating and deleting metric images' do
        expect(permissions(non_member, issue)).to be_disallowed(:read_issuable_metric_image, :upload_issuable_metric_image, :update_issuable_metric_image, :destroy_issuable_metric_image)
      end

      it 'allows guests to read metric images, and create + delete in their own issues' do
        expect(permissions(guest, issue)).to be_allowed(:read_issuable_metric_image)
        expect(permissions(guest, issue)).to be_disallowed(:upload_issuable_metric_image, :update_issuable_metric_image, :destroy_issuable_metric_image)

        expect(permissions(guest, guest_issue)).to be_allowed(:read_issuable_metric_image, :upload_issuable_metric_image, :update_issuable_metric_image, :destroy_issuable_metric_image)
      end

      it 'allows reporters to create and delete metric images' do
        expect(permissions(reporter, issue)).to be_allowed(:read_issuable_metric_image, :upload_issuable_metric_image, :update_issuable_metric_image, :destroy_issuable_metric_image)
        expect(permissions(reporter, reporter_issue)).to be_allowed(:read_issuable_metric_image, :upload_issuable_metric_image, :update_issuable_metric_image, :destroy_issuable_metric_image)
      end

      context 'Timeline events' do
        it 'disallows non-members from reading timeline events' do
          expect(permissions(non_member, issue)).to be_disallowed(:read_incident_management_timeline_event)
        end

        it 'allows guests to read time line events' do
          expect(permissions(guest, issue)).to be_allowed(:read_incident_management_timeline_event)
        end

        it 'disallows reporters from managing timeline events' do
          expect(permissions(reporter, issue)).to be_disallowed(:admin_incident_management_timeline_event)
        end

        it 'allows developers to manage timeline events' do
          expect(permissions(developer, issue)).to be_allowed(:admin_incident_management_timeline_event)
        end

        context 'when timeline events are not available' do
          before do
            allow(::Gitlab::IncidentManagement).to receive(:timeline_events_available?).with(project).and_return(false)
          end

          it 'disallows guests from reading timeline events' do
            expect(permissions(guest, issue)).to be_disallowed(:read_incident_management_timeline_event)
          end

          it 'disallows developers from managing timeline events' do
            expect(permissions(developer, issue)).to be_disallowed(:admin_incident_management_timeline_event)
          end
        end
      end
    end
  end
end
