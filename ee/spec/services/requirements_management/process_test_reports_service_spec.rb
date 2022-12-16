# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::ProcessTestReportsService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    subject { described_class.new(build).execute }

    context 'when requirements feature is available' do
      before do
        stub_licensed_features(requirements: true)
      end

      context 'when there are no requirements in the project' do
        let_it_be(:build) { create(:ee_ci_build, :requirements_v2_report, project: project, user: user) }

        it 'does not create any test report' do
          expect { subject }.not_to change { RequirementsManagement::TestReport }
        end
      end

      context 'when there are requirements' do
        let_it_be(:requirement) { create(:work_item, :requirement, state: :opened, project: project) }
        let_it_be(:requirement2) { create(:work_item, :requirement, state: :opened, project: project) }
        let_it_be(:requirement3) { create(:work_item, :requirement, state: :closed, project: project) }

        context 'when user is not allowed to create requirements test reports' do
          let_it_be(:build) { create(:ee_ci_build, :requirements_v2_report, project: project, user: user) }

          it 'raises an exception' do
            expect { subject }.to raise_exception(Gitlab::Access::AccessDeniedError)
          end
        end

        context 'when user can create requirements test reports' do
          before do
            project.add_reporter(user)
          end

          context 'when using artifact with work items iids' do
            let_it_be_with_refind(:build) do
              create(:ee_ci_build, :requirements_v2_report, project: project, user: user)
            end

            it 'creates new test report for each open requirement' do
              expect(RequirementsManagement::TestReport).to receive(:persist_requirement_reports)
                .with(build, an_instance_of(Gitlab::Ci::Reports::RequirementsManagement::Report)).and_call_original

              expect { subject }.to change { RequirementsManagement::TestReport.count }.by(2)
            end

            it 'does not create test report for the same pipeline and user twice' do
              expect { subject }.to change { RequirementsManagement::TestReport.count }.by(2)

              expect { subject }.not_to change { RequirementsManagement::TestReport }
            end

            context 'when there is also a report with legacy requirements iids' do
              it 'ignores legacy requirement iids report' do
                create(:ee_ci_job_artifact, :all_passing_requirements, job: build)

                expect(RequirementsManagement::TestReport).not_to receive(:persist_requirement_reports)
                  .with(build, an_instance_of(Gitlab::Ci::Reports::RequirementsManagement::Report), legacy: true)

                subject
              end
            end
          end

          context 'when using artifact with legacy requirement iids' do
            let_it_be(:build) { create(:ee_ci_build, :requirements_report, project: project, user: user) }

            it 'creates new test report for each open requirement' do
              expect(RequirementsManagement::TestReport).to receive(:persist_requirement_reports)
                .with(build, an_instance_of(Gitlab::Ci::Reports::RequirementsManagement::Report), legacy: true)
                .and_call_original

              expect { subject }.to change { RequirementsManagement::TestReport.count }.by(2)
            end

            it 'does not create test report for the same pipeline and user twice' do
              expect { subject }.to change { RequirementsManagement::TestReport.count }.by(2)

              expect { subject }.not_to change { RequirementsManagement::TestReport }
            end
          end

          context 'when build does not contain any requirements report' do
            let(:build) { create(:ee_ci_build, project: project, user: user) }

            it 'does not create any test report' do
              expect { subject }.not_to change { RequirementsManagement::TestReport }
            end
          end
        end
      end
    end

    context 'when requirements feature is not available' do
      let_it_be(:build) { create(:ee_ci_build, :requirements_v2_report, project: project, user: user) }

      it 'does not create any test report' do
        expect { subject }.not_to change { RequirementsManagement::TestReport }
      end
    end
  end
end
