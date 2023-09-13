# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::Violations::ExportService, feature_category: :compliance_management do
  subject(:service) { described_class.new user: user, namespace: group, filters: filters, sort: sort }

  let_it_be(:user) { create(:user, name: 'Morty Smith') }
  let_it_be(:group) { create(:group, name: 'parent') }
  let(:filters) { {} }
  let(:sort) { nil }

  let_it_be(:csv_header) do
    "Title,Severity,Violation,Merge request,Change made by User ID,Date merged"
  end

  let_it_be(:project) do
    create :project, :repository, namespace: group, name: 'Parent Project', path: 'parent_project'
  end

  describe '#execute' do
    context 'without visibility to user' do
      it { expect(service.execute).to be_error }

      it 'exports a CSV payload with just the header' do
        expect(service.execute.message).to eq "Access to group denied for user with ID: #{user.id}"
      end
    end

    context 'with a authorized user' do
      before_all do
        group.add_owner(user)
      end

      context 'with no violations' do
        it 'exports a CSV payload without violations' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload).to eq "#{csv_header}\n"
        end
      end

      context 'with a violation' do
        let(:violator) { create :user, name: "Hans Strucker", username: "hydra" }
        let(:merge_time) { Time.zone.parse "2022-04-20T16:20+0" }

        it 'exports a CSV payload' do
          mr = create :merge_request, title: 'hey', source_project: project, target_project: project, author: violator
          merge_request_url = Gitlab::Routing.url_helpers.project_merge_request_url(project, mr)
          create :compliance_violation, merge_request: mr, violating_user: violator, merged_at: merge_time

          expected_row = "hey,info,approved_by_merge_request_author,#{merge_request_url},#{violator.id},#{merge_time}"

          export = <<~EXPORT
          #{csv_header}
          #{expected_row}
          EXPORT

          expect(service.execute.payload).to eq export
        end

        it "avoids N+1 when exporting" do
          service.execute # warm up cache

          mrs = create_list(
            :merge_request,
            2,
            :unique_branches,
            source_project: project,
            target_project: project,
            author: violator
          )

          build :compliance_violation do |violation|
            violation.target_project_id = project.id
            violation.merge_request_id = mrs.first.id
            violation.save!
          end

          control = ActiveRecord::QueryRecorder.new(query_recorder_debug: true) { service.execute }

          build :compliance_violation do |violation|
            violation.target_project_id = project.id
            violation.merge_request_id = mrs.last.id
            violation.save!
          end

          expect { service.execute }.not_to exceed_query_limit(control)
        end
      end
    end
  end

  describe '#email_export' do
    let(:worker) { ComplianceManagement::ViolationExportMailerWorker }

    context "with compliance_violation_csv_export ff implicitly enabled" do
      it 'enqueues a worker' do
        expect(worker).to receive(:perform_async).with(user.id, group.id, {}, nil)

        expect(service.email_export).to be_success
      end
    end

    context "with compliance_violation_csv_export ff disabled" do
      it 'skips enqueue of a worker' do
        stub_feature_flags compliance_violation_csv_export: false

        expect(worker).not_to receive(:perform_async)

        expect(service.email_export).to be_success
      end
    end
  end
end
