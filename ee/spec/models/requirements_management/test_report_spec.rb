# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::TestReport do
  describe 'associations' do
    subject { build(:test_report) }

    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:requirement_issue) }
    it { is_expected.to belong_to(:build) }
  end

  describe 'validations' do
    subject { build(:test_report) }

    let(:requirement) { build(:requirement) }
    let(:requirement_issue) { build(:requirement_issue) }

    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:requirement_issue) }

    context 'requirements associations' do
      subject { build(:test_report, requirement_issue: requirement_issue_arg) }

      context 'when only requirement issue is set' do
        let(:requirement_arg) { nil }

        it_behaves_like 'a model with a requirement issue association'
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
    let_it_be(:build) { create(:ee_ci_build, :requirements_report, project: project) }

    subject { described_class.persist_requirement_reports(build, ci_report) }

    context 'if the CI report contains no entries' do
      let(:ci_report) { Gitlab::Ci::Reports::RequirementsManagement::Report.new }

      it 'does not create any test reports' do
        expect { subject }.not_to change { RequirementsManagement::TestReport.count }
      end
    end

    context 'if the CI report contains some entries' do
      context 'and the entries are valid' do
        let(:ci_report) do
          Gitlab::Ci::Reports::RequirementsManagement::Report.new.tap do |report|
            report.add_requirement('1', 'passed')
            report.add_requirement('2', 'failed')
            report.add_requirement('3', 'passed')
          end
        end

        it 'creates test report with expected status for each open requirement' do
          requirement1 = create(:requirement, state: :opened, project: project)
          requirement2 = create(:requirement, state: :opened, project: project)
          create(:requirement, state: :opened) # different project
          create(:requirement, state: :archived, project: project) # archived

          expect { subject }.to change { RequirementsManagement::TestReport.count }.by(2)

          reports = RequirementsManagement::TestReport.where(build: build)

          expect(reports).to match_array([
            have_attributes(requirement_issue: requirement1.requirement_issue,
                            author: build.user,
                            state: 'passed'),
            have_attributes(requirement_issue: requirement2.requirement_issue,
                            author: build.user,
                            state: 'failed')

          ])
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

        it 'creates test report with expected status for each open requirement' do
          # ignore requirement IIDs that appear in the test but are missing
          create(:requirement, state: :opened, project: project, iid: 1)
          create(:requirement, state: :opened, project: project, iid: 2)

          expect { subject }.not_to change { RequirementsManagement::TestReport.count }
        end
      end
    end
  end

  describe '.build_report' do
    let_it_be(:user) { create(:user) }
    let_it_be(:build_author) { create(:user) }
    let_it_be(:build) { create(:ci_build, author: build_author) }
    let_it_be(:requirement_issue) { create(:requirement_issue) }

    let(:now) { Time.current }

    context 'when build is passed as argument' do
      it 'builds test report with correct attributes' do
        test_report = described_class.build_report(requirement_issue: requirement_issue, author: user, state: 'failed', build: build, timestamp: now)

        expect(test_report.author).to eq(build.author)
        expect(test_report.build).to eq(build)
        expect(test_report.requirement_issue).to eq(requirement_issue)
        expect(test_report.state).to eq('failed')
        expect(test_report.created_at).to eq(now)
      end
    end

    context 'when build is not passed as argument' do
      it 'builds test report with correct attributes' do
        test_report = described_class.build_report(requirement_issue: requirement_issue, author: user, state: 'passed', timestamp: now)

        expect(test_report.author).to eq(user)
        expect(test_report.build).to eq(nil)
        expect(test_report.requirement_issue).to eq(requirement_issue)
        expect(test_report.state).to eq('passed')
        expect(test_report.created_at).to eq(now)
      end
    end
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:test_report) }
    let(:parent) { model.build }
  end
end
