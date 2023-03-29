# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::StatusService::UpdateService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:work_item) { create(:work_item, :requirement, project: project, author: user) }

  let(:service) { described_class.new(widget: widget, current_user: user) }
  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Status) } }

  def work_item_status
    state = work_item.reload.requirement&.last_test_report_state
    ::WorkItems::Widgets::Status::STATUS_MAP[state]
  end

  describe '#update' do
    subject { service.before_update_in_transaction(params: params) }

    shared_examples 'work item and status is unchanged' do
      it 'does not change work item status value' do
        expect { subject }
          .to not_change { work_item_status }
          .and not_change { work_item }
      end
    end

    shared_examples 'status is updated' do |new_value|
      it 'updates work item status value' do
        expect { subject }
          .to change { work_item_status }.to(new_value)
      end
    end

    context 'when status feature is licensed' do
      before do
        stub_licensed_features(requirements: true)
      end

      context 'when user cannot update work item' do
        let(:params) { { status: "failed" } }

        before do
          project.add_guest(user)
        end

        it_behaves_like 'work item and status is unchanged'
      end

      context 'when user can update work item' do
        before do
          project.add_reporter(user)
        end

        context 'when status param is present' do
          context 'when status param is valid' do
            let(:params) { { status: 'failed' } }

            it_behaves_like 'status is updated', 'failed'
          end

          context 'when status param is equivalent' do
            let(:params) { { status: 'passed' } }

            it_behaves_like 'status is updated', 'satisfied'
          end

          context 'when status param is invalid' do
            where(:new_status) do
              %w[unverified nonsense satisfied]
            end

            with_them do
              let(:params) { { status: new_status } }

              it 'errors' do
                expect { subject }.to raise_error(ArgumentError, /is not a valid state/)
              end
            end
          end
        end

        context 'when widget does not exist in new type' do
          let(:params) { {} }

          let_it_be(:test_report1) { create(:test_report, requirement_issue: work_item) }
          let_it_be(:test_report2) { create(:test_report, requirement_issue: work_item) }
          let_it_be(:other_test_report) do
            create(:test_report, requirement_issue: create(:work_item, :requirement, project: project))
          end

          before do
            allow(service).to receive(:new_type_excludes_widget?).and_return(true)
          end

          it "deletes the associated test report and requirement" do
            requirement = work_item.requirement

            expect { subject }.to change { work_item.test_reports.count }.from(2).to(0)

            expect(RequirementsManagement::TestReport.exists?(test_report1.id)).to eq(false)
            expect(RequirementsManagement::TestReport.exists?(test_report2.id)).to eq(false)
            expect(RequirementsManagement::Requirement.exists?(requirement.id)).to eq(false)
            expect(RequirementsManagement::TestReport.exists?(other_test_report.id)).to eq(true)
          end
        end

        context 'when status param is not present' do
          let(:params) { {} }

          it_behaves_like 'work item and status is unchanged'
        end

        context 'when status param is nil' do
          let(:params) { { status: nil } }

          it_behaves_like 'work item and status is unchanged'
        end
      end
    end
  end
end
