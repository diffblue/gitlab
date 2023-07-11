# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::TestReport, feature_category: :requirements_management do
  describe 'associations' do
    subject { build(:test_report) }

    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:requirement_issue) }
    it { is_expected.to belong_to(:build) }
  end

  describe 'validations' do
    subject { build(:test_report) }

    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:requirement_issue) }

    context 'requirements associations' do
      subject { build(:test_report, requirement_issue: requirement_issue_arg) }

      context 'when only requirement issue is set' do
        it_behaves_like 'a model with a requirement issue association'
      end
    end

    context 'when requirement_issue is not of type requirement' do
      subject { build(:test_report, requirement_issue: create(:issue)) }

      specify do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:requirement_issue]).to include(/must be a `requirement`/)
      end
    end
  end

  describe 'scopes' do
    let_it_be(:user) { create(:user) }
    let_it_be(:build) { create(:ci_build) }
    let_it_be(:report1) { create(:test_report, author: user, build: build) }
    let_it_be(:report2) { create(:test_report, author: user) }
    let_it_be(:report3) { create(:test_report, build: build) }
    let_it_be(:report4) { create(:test_report, build: nil) }

    describe '.for_user_build' do
      it "returns only test reports matching build's user and pipeline" do
        expect(described_class.for_user_build(user.id, build.id)).to match_array([report1])
      end
    end

    describe '.with_build' do
      it 'returns only test reports which reference a CI build' do
        expect(described_class.with_build).to match_array([report1, report2, report3])
      end
    end

    describe '.without_build' do
      it 'returns only test reports which do not refer any CI build' do
        expect(described_class.without_build).to match_array([report4])
      end
    end
  end

  describe '.persist_requirement_reports' do
    let_it_be(:project) { create(:project) }

    subject { described_class.persist_requirement_reports(build, ci_report) }

    context 'if the CI report contains no entries' do
      let_it_be(:build) { create(:ee_ci_build, :requirements_v2_report, project: project) }
      let(:ci_report) { Gitlab::Ci::Reports::RequirementsManagement::Report.new }

      it 'does not create any test reports' do
        expect { subject }.not_to change { RequirementsManagement::TestReport.count }
      end
    end

    context 'if the CI report contains some entries' do
      context 'and the entries are valid' do
        context 'and legacy is false' do
          let_it_be(:build) { create(:ee_ci_build, :requirements_v2_report, project: project) }
          let_it_be(:requirement1) { create(:work_item, :requirement, iid: 11, state: :opened, project: project) }
          let_it_be(:requirement2) { create(:work_item, :requirement, iid: 13, state: :opened, project: project) }
          let(:ci_report) do
            Gitlab::Ci::Reports::RequirementsManagement::Report.new.tap do |report|
              # Keep iids not sequential here to make sure it is properly tested
              report.add_requirement('11', 'passed')
              report.add_requirement('13', 'failed')
              report.add_requirement('16', 'passed')
            end
          end

          before_all do
            create(:work_item, :requirement, iid: 11, state: :opened) # different project
            create(:work_item, :requirement, iid: 16, state: :closed, project: project) # archived
          end

          it 'creates test report with expected status for each open requirement' do
            expect { subject }.to change { RequirementsManagement::TestReport.count }.by(2)

            reports = described_class.where(build: build)

            requirement_type_id = WorkItems::Type.requirement.first.id
            expect(reports).to match_array(
              [
                have_attributes(
                  requirement_issue: have_attributes(id: requirement1.id, work_item_type_id: requirement_type_id),
                  author: build.user,
                  state: 'passed', uses_legacy_iid: false
                ),
                have_attributes(
                  requirement_issue: have_attributes(id: requirement2.id, work_item_type_id: requirement_type_id),
                  author: build.user,
                  state: 'failed', uses_legacy_iid: false
                )
              ])
          end

          context 'when all_passed? in ci_report' do
            let(:ci_report) do
              Gitlab::Ci::Reports::RequirementsManagement::Report.new.tap do |report|
                report.add_requirement('*', 'passed')
              end
            end

            it 'creates test report with expected status for each open requirement' do
              expect { subject }.to change { RequirementsManagement::TestReport.count }.by(2)

              reports = described_class.where(build: build)

              requirement_type_id = WorkItems::Type.requirement.first.id
              expect(reports).to match_array(
                [
                  have_attributes(
                    requirement_issue: have_attributes(id: requirement1.id, work_item_type_id: requirement_type_id),
                    author: build.user,
                    state: 'passed', uses_legacy_iid: false
                  ),
                  have_attributes(
                    requirement_issue: have_attributes(id: requirement2.id, work_item_type_id: requirement_type_id),
                    author: build.user,
                    state: 'passed', uses_legacy_iid: false
                  )
                ])
            end
          end
        end

        context 'when legacy is true' do
          let(:ci_report) do
            Gitlab::Ci::Reports::RequirementsManagement::Report.new.tap do |report|
              report.add_requirement('1', 'passed')
              report.add_requirement('2', 'failed')
              report.add_requirement('3', 'passed')
            end
          end

          let_it_be(:build) { create(:ee_ci_build, :requirements_report, project: project) }

          subject { described_class.persist_requirement_reports(build, ci_report, legacy: true) }

          it 'creates test report with expected status for each open requirement' do
            requirement1 = create(:work_item, :requirement, state: :opened, project: project)
            requirement2 = create(:work_item, :requirement, state: :opened, project: project)
            create(:work_item, :requirement, state: :opened) # different project
            create(:work_item, :requirement, state: :closed, project: project) # archived

            expect { subject }.to change { RequirementsManagement::TestReport.count }.by(2)

            reports = described_class.where(build: build)

            requirement_type_id = WorkItems::Type.requirement.first.id
            expect(reports).to match_array(
              [
                have_attributes(
                  requirement_issue: have_attributes(id: requirement1.id, work_item_type_id: requirement_type_id),
                  author: build.user,
                  state: 'passed', uses_legacy_iid: true
                ),
                have_attributes(
                  requirement_issue: have_attributes(id: requirement2.id, work_item_type_id: requirement_type_id),
                  author: build.user,
                  state: 'failed', uses_legacy_iid: true
                )
              ])
          end
        end
      end

      context 'and the entries are not valid' do
        let(:ci_report) do
          Gitlab::Ci::Reports::RequirementsManagement::Report.new.tap do |report|
            report.add_requirement('0', 'passed')
            report.add_requirement('1', 'nonsense')
            report.add_requirement('2', nil)
          end
        end

        let_it_be(:build) { create(:ee_ci_build, :requirements_v2_report, project: project) }

        it 'does not create any test reports' do
          # ignore requirement IIDs that appear in the test but are missing
          create(:work_item, :requirement, state: :opened, project: project, iid: 1)
          create(:work_item, :requirement, state: :opened, project: project, iid: 2)

          expect { subject }.not_to change { RequirementsManagement::TestReport.count }
        end
      end
    end
  end

  describe '.build_report' do
    let_it_be(:user) { create(:user) }
    let_it_be(:build_author) { create(:user) }
    let_it_be(:build) { create(:ci_build, author: build_author) }
    let_it_be(:requirement) { create(:work_item, :requirement) }

    let(:now) { Time.current }

    shared_examples 'builds the expected reports' do |expected_legacy_value|
      context 'when build is passed as argument' do
        it 'builds test report with correct attributes' do
          test_report = described_class.build_report(requirement_issue: requirement, author: user, state: 'failed', build: build, timestamp: now, legacy: expected_legacy_value)

          expect(test_report.author).to eq(build.author)
          expect(test_report.build).to eq(build)
          expect(test_report.issue_id).to eq(requirement.id)
          expect(test_report.state).to eq('failed')
          expect(test_report.created_at).to eq(now)
          expect(test_report.uses_legacy_iid).to eq expected_legacy_value
        end
      end

      context 'when build is not passed as argument' do
        it 'builds test report with correct attributes' do
          test_report = described_class.build_report(requirement_issue: requirement, author: user, state: 'passed', timestamp: now, legacy: expected_legacy_value)

          expect(test_report.author).to eq(user)
          expect(test_report.build).to eq(nil)
          expect(test_report.issue_id).to eq(requirement.id)
          expect(test_report.state).to eq('passed')
          expect(test_report.created_at).to eq(now)
          expect(test_report.uses_legacy_iid).to eq expected_legacy_value
        end
      end
    end

    it_behaves_like 'builds the expected reports', false

    context 'when legacy is true' do
      it_behaves_like 'builds the expected reports', true
    end

    context 'when state param is invalid' do
      context 'when state is nil' do
        it 'test report is not valid' do
          report = described_class.build_report(requirement_issue: requirement, author: user, state: nil, timestamp: now)

          expect(report).not_to be_valid
        end
      end

      context 'when state is a non-nil invalid value' do
        it 'raises ArgumentError' do
          expect do
            described_class.build_report(requirement_issue: requirement, author: user, state: 'nonsense', timestamp: now)
          end.to raise_error(ArgumentError, /not a valid state/)
        end
      end
    end
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:test_report) }
    let(:parent) { model.build }
  end
end
