# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Feedback, feature_category: :vulnerability_management do
  it {
    is_expected.to(
      define_enum_for(:feedback_type)
      .with_values(dismissal: 0, issue: 1, merge_request: 2)
      .with_prefix(:for)
    )
  }

  it { is_expected.to define_enum_for(:category) }
  it { is_expected.to define_enum_for(:dismissal_reason) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:comment_author).class_name('User') }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to belong_to(:merge_request) }
    it { is_expected.to belong_to(:pipeline).class_name('Ci::Pipeline').with_foreign_key('pipeline_id') }
    it { is_expected.to belong_to(:finding).with_primary_key('uuid').class_name('Vulnerabilities::Finding').with_foreign_key('finding_uuid') }
    it { is_expected.to belong_to(:security_finding).with_primary_key('uuid').class_name('Security::Finding').with_foreign_key('finding_uuid') }
  end

  describe 'validations' do
    let_it_be(:project) { create(:project) }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:feedback_type) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:project_fingerprint) }
    it { is_expected.to validate_length_of(:comment).is_at_most(50_000) }

    context 'pipeline is nil' do
      let(:feedback) { build(:vulnerability_feedback, project: project, pipeline_id: nil) }

      it 'is valid' do
        expect(feedback).to be_valid
      end
    end

    context 'pipeline has the same project_id' do
      let(:feedback) { build(:vulnerability_feedback, project: project) }

      it 'is valid' do
        expect(feedback.project_id).to eq(feedback.pipeline.project_id)
        expect(feedback).to be_valid
      end
    end

    context 'pipeline_id does not exist' do
      let(:feedback) { build(:vulnerability_feedback, project: project, pipeline_id: -100) }

      it 'is invalid' do
        expect(feedback.project_id).not_to eq(feedback.pipeline_id)
        expect(feedback).not_to be_valid
      end
    end

    context 'pipeline has a different project_id' do
      let(:pipeline) { create(:ci_pipeline, project: create(:project)) }
      let(:feedback) { build(:vulnerability_feedback, project: project, pipeline: pipeline) }

      it 'is invalid' do
        expect(feedback.project_id).not_to eq(pipeline.project_id)
        expect(feedback).not_to be_valid
      end
    end

    context 'comment is set' do
      let(:feedback) { build(:vulnerability_feedback, project: project, comment: 'a comment' ) }

      it 'validates presence of comment_timestamp' do
        expect(feedback).to validate_presence_of(:comment_timestamp)
      end

      it 'validates presence of comment_author' do
        expect(feedback).to validate_presence_of(:comment_author)
      end
    end
  end

  describe 'callbacks' do
    let_it_be(:project) { create(:project) }
    let_it_be_with_refind(:pipeline) { create(:ci_pipeline, project: project) }

    shared_examples 'touches the pipeline' do
      context 'when feedback is for dismissal' do
        let_it_be_with_refind(:feedback) { create(:vulnerability_feedback, :dismissal, project: project) }

        context 'when pipeline is not assigned to feedback' do
          it 'does not touch the pipeline' do
            expect(pipeline).not_to receive(:touch)
            subject
          end
        end

        context 'when pipeline is assigned to feedback' do
          before do
            feedback.update!(pipeline: pipeline)
          end

          context 'when pipeline was updated less than 5 minutes ago' do
            before do
              pipeline.touch(time: 3.minutes.ago)
            end

            it 'touches the pipeline' do
              expect(pipeline).not_to receive(:touch)
              subject
            end
          end

          context 'when pipeline was updated more than 5 minutes ago' do
            before do
              pipeline.touch(time: 6.minutes.ago)
            end

            it 'touches the pipeline' do
              expect(pipeline).to receive(:touch)
              subject
            end

            context 'when pipeline touch raises ActiveRecord::StaleObjectError' do
              before do
                allow(pipeline).to receive(:touch).and_raise(ActiveRecord::StaleObjectError)
              end

              it 'does not raise an error' do
                expect { subject }.not_to raise_error
              end
            end
          end
        end
      end

      context 'when feedback is not for dismissal' do
        let_it_be_with_refind(:feedback) { create(:vulnerability_feedback, :issue) }

        context 'when pipeline is not assigned to feedback' do
          it 'does not touch the pipeline' do
            expect(pipeline).not_to receive(:touch)
            subject
          end
        end
      end
    end

    context 'after_save :touch_pipeline' do
      subject { feedback.update!(vulnerability_data: { category: 'dependency_scanning' }) }

      it_behaves_like 'touches the pipeline'
    end

    context 'after_destroy :touch_pipeline' do
      subject { feedback.destroy! }

      it_behaves_like 'touches the pipeline'
    end
  end

  describe '.by_finding_uuid' do
    let(:feedback_1) { create(:vulnerability_feedback) }
    let(:feedback_2) { create(:vulnerability_feedback) }

    subject { described_class.by_finding_uuid([feedback_2.finding_uuid]) }

    it { is_expected.to eq([feedback_2]) }
  end

  describe '.with_category' do
    it 'filters by category' do
      described_class.categories.each do |category, _|
        create(:vulnerability_feedback, category: category)
      end

      expect(described_class.count).to eq described_class.categories.length

      expected, _ = described_class.categories.first

      feedback = described_class.with_category(expected)

      expect(feedback.length).to eq 1
      expect(feedback.first.category).to eq expected
    end
  end

  describe '.with_feedback_type' do
    it 'filters by feedback_type' do
      create(:vulnerability_feedback, :dismissal)
      create(:vulnerability_feedback, :issue)
      create(:vulnerability_feedback, :merge_request)

      feedback = described_class.with_feedback_type('issue')

      expect(feedback.length).to eq 1
      expect(feedback.first.feedback_type).to eq 'issue'
    end
  end

  describe '#has_comment?' do
    let_it_be(:project) { create(:project) }

    let(:feedback) { build(:vulnerability_feedback, project: project, comment: comment, comment_author: comment_author) }
    let(:comment) { 'a comment' }
    let(:comment_author) { build(:user) }

    subject { feedback.has_comment? }

    context 'comment and comment_author are set' do
      it { is_expected.to be_truthy }
    end

    context 'comment is set and comment_author is not' do
      let(:comment_author) { nil }

      it { is_expected.to be_falsy }
    end

    context 'comment and comment_author are not set' do
      let(:comment) { nil }
      let(:comment_author) { nil }

      it { is_expected.to be_falsy }
    end
  end

  describe '#find_or_init_for' do
    let(:group) { create(:group) }
    let(:project) { create(:project, :public, :repository, namespace: group) }
    let(:user) { create(:user) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:finding_uuid) { SecureRandom.uuid }
    let(:project_fingerprint) { '418291a26024a1445b23fe64de9380cdcdfd1fa8' }

    let(:feedback_params) do
      {
        finding_uuid: finding_uuid,
        feedback_type: 'dismissal',
        pipeline_id: pipeline.id,
        category: 'sast',
        project_fingerprint: project_fingerprint,
        author: user,
        vulnerability_data: {
          category: 'sast',
          priority: 'Low',
          line: '41',
          file: 'subdir/src/main/java/com/gitlab/security_products/tests/App.java',
          cve: '818bf5dacb291e15d9e6dc3c5ac32178:PREDICTABLE_RANDOM',
          name: 'Predictable pseudorandom number generator',
          description: 'Description of Predictable pseudorandom number generator',
          tool: 'find_sec_bugs'
        }
      }
    end

    context 'when params are valid' do
      subject(:feedback) { described_class.find_or_init_for(feedback_params) }

      context 'when there is no record for the given params' do
        it 'inits the feedback' do
          is_expected.to have_attributes(id: nil, finding_uuid: finding_uuid, feedback_type: 'dismissal', category: 'sast', author: user)
        end
      end

      context 'when there is a record for the given params' do
        context 'when the existing record matches by finding_uuid' do
          let!(:existing_feedback) { create(:vulnerability_feedback, :dismissal, finding_uuid: finding_uuid, project_fingerprint: 'foo') }

          it { is_expected.to eq(existing_feedback) }
        end

        context 'when the existing record does not match by finding uuid' do
          let!(:existing_feedback) { create(:vulnerability_feedback, :dismissal, finding_uuid: nil, project_fingerprint: project_fingerprint) }

          it { is_expected.to eq(existing_feedback) }
        end
      end
    end

    context 'when params are invalid' do
      it 'raises ArgumentError when given a bad feedback_type value' do
        feedback_params[:feedback_type] = 'foo'

        expect { described_class.find_or_init_for(feedback_params) }.to raise_error(ArgumentError, /feedback_type/)
      end

      it 'raises ArgumentError when given a bad category value' do
        feedback_params[:category] = 'foo'

        expect { described_class.find_or_init_for(feedback_params) }.to raise_error(ArgumentError, /category/)
      end
    end
  end

  context 'loose foreign key on vulnerability_feedback.pipeline_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:ci_pipeline) }
      let!(:model) { create(:vulnerability_feedback, project: parent.project, pipeline: parent) }
    end
  end
end
