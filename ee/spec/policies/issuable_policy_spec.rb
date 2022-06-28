# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuablePolicy, models: true do
  let_it_be(:non_member) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }

  let(:guest_issue) { create(:issue, project: project, author: guest) }
  let(:reporter_issue) { create(:issue, project: project, author: reporter) }
  let(:incident_issue) { create(:incident, project: project, author: developer) }

  before do
    project.add_guest(guest)
    project.add_reporter(reporter)
    project.add_developer(developer)
  end

  def permissions(user, issue)
    described_class.new(user, issue)
  end

  describe '#rules' do
    shared_examples 'issuable resource links access' do
      it 'disallows non members' do
        expect(permissions(non_member, incident_issue)).to be_disallowed(:admin_issuable_resource_link)
        expect(permissions(non_member, incident_issue)).to be_disallowed(:read_issuable_resource_link)
      end

      it 'disallows guests' do
        expect(permissions(guest, incident_issue)).to be_disallowed(:admin_issuable_resource_link)
        expect(permissions(guest, incident_issue)).to be_disallowed(:read_issuable_resource_link)
      end

      it 'disallows all on non-incident issue type' do
        expect(permissions(non_member, issue)).to be_disallowed(:admin_issuable_resource_link)
        expect(permissions(guest, issue)).to be_disallowed(:admin_issuable_resource_link)
        expect(permissions(developer, issue)).to be_disallowed(:admin_issuable_resource_link)
        expect(permissions(reporter, issue)).to be_disallowed(:admin_issuable_resource_link)
        expect(permissions(non_member, issue)).to be_disallowed(:read_issuable_resource_link)
        expect(permissions(guest, issue)).to be_disallowed(:read_issuable_resource_link)
        expect(permissions(developer, issue)).to be_disallowed(:read_issuable_resource_link)
        expect(permissions(reporter, issue)).to be_disallowed(:read_issuable_resource_link)
      end
    end

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

      context 'Create, read, delete issuable resource links' do
        context 'when available' do
          before do
            allow(::Gitlab::IncidentManagement).to receive(:issuable_resource_links_available?).with(project).and_return(true)
          end

          it_behaves_like 'issuable resource links access'

          it 'allows developers' do
            expect(permissions(developer, incident_issue)).to be_allowed(:admin_issuable_resource_link)
            expect(permissions(developer, incident_issue)).to be_allowed(:read_issuable_resource_link)
          end

          it 'allows reporters' do
            expect(permissions(reporter, incident_issue)).to be_allowed(:admin_issuable_resource_link)
            expect(permissions(reporter, incident_issue)).to be_allowed(:read_issuable_resource_link)
          end
        end

        context 'when not available' do
          before do
            allow(::Gitlab::IncidentManagement).to receive(:issuable_resource_links_available?).with(project).and_return(false)
          end

          it_behaves_like 'issuable resource links access'

          it 'disallows developers' do
            expect(permissions(developer, incident_issue)).to be_disallowed(:admin_issuable_resource_link)
            expect(permissions(developer, incident_issue)).to be_disallowed(:read_issuable_resource_link)
          end

          it 'disallows reporters' do
            expect(permissions(reporter, incident_issue)).to be_disallowed(:admin_issuable_resource_link)
            expect(permissions(reporter, incident_issue)).to be_disallowed(:read_issuable_resource_link)
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

      context 'Create, read, delete issuable resource links' do
        context 'when available' do
          before do
            allow(::Gitlab::IncidentManagement).to receive(:issuable_resource_links_available?).with(project).and_return(true)
          end

          it_behaves_like 'issuable resource links access'

          it 'allows developers' do
            expect(permissions(developer, incident_issue)).to be_allowed(:admin_issuable_resource_link)
            expect(permissions(developer, incident_issue)).to be_allowed(:read_issuable_resource_link)
          end

          it 'allows reporters' do
            expect(permissions(reporter, incident_issue)).to be_allowed(:admin_issuable_resource_link)
            expect(permissions(reporter, incident_issue)).to be_allowed(:read_issuable_resource_link)
          end
        end
      end
    end
  end
end
