# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Statistic, feature_category: :vulnerability_management do
  describe 'associations' do
    it { is_expected.to belong_to(:project).required(true) }
    it { is_expected.to belong_to(:pipeline).required(false) }
  end

  describe 'validations' do
    it { is_expected.to validate_numericality_of(:total).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:critical).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:high).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:medium).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:low).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:unknown).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:info).is_greater_than_or_equal_to(0) }
    it { is_expected.to define_enum_for(:letter_grade).with_values(%i(a b c d f)) }
  end

  describe '.before_save' do
    describe '#assign_letter_grade' do
      let_it_be(:pipeline) { create(:ci_pipeline) }
      let_it_be(:project) { pipeline.project }

      let(:statistic) { build(:vulnerability_statistic, letter_grade: nil, critical: 5, project: project) }

      subject(:save_statistic) { statistic.save! }

      it 'assigns the letter_grade' do
        expect { save_statistic }.to change { statistic.letter_grade }.from(nil).to('f')
      end
    end
  end

  describe '.by_grade' do
    let!(:statistic_grade_a) { create(:vulnerability_statistic, letter_grade: :a) }

    subject { described_class.by_grade(:a) }

    before do
      %w[b c d f].each { create(:vulnerability_statistic, :"grade_#{_1}") }
    end

    it { is_expected.to match_array([statistic_grade_a]) }
  end

  describe '.letter_grade_for' do
    subject { described_class.letter_grade_for(object) }

    context 'when the given object is an instance of Vulnerabilities::Statistic' do
      let(:object) { build(:vulnerability_statistic, critical: 1) }

      it { is_expected.to eq(4) }
    end

    context 'when the given object is a Hash' do
      let(:object) { { 'high' => 1 } }

      it { is_expected.to eq(3) }
    end
  end

  describe '.letter_grade_sql_for' do
    using RSpec::Parameterized::TableSyntax

    where(:target_critical, :target_unknown, :target_high, :target_medium, :target_low, :excluded_critical, :excluded_unknown, :excluded_high, :excluded_medium, :excluded_low) do
      0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0

      0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1
      0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0
      0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 1

      0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 1 | 1
      0 | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 1
      0 | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 1 | 1

      0 | 0 | 0 | 1 | 1 | 0 | 0 | 1 | 1 | 1
      0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | 1 | 1
      0 | 0 | 1 | 1 | 1 | 0 | 0 | 1 | 1 | 1

      0 | 0 | 1 | 1 | 1 | 0 | 1 | 1 | 1 | 1
      0 | 1 | 1 | 1 | 1 | 0 | 0 | 1 | 1 | 1
      0 | 1 | 1 | 1 | 1 | 0 | 1 | 1 | 1 | 1

      0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1
      1 | 1 | 1 | 1 | 1 | 0 | 1 | 1 | 1 | 1
      1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1
    end

    with_them do
      let(:target) { "(#{target_critical}, #{target_unknown}, #{target_high}, #{target_medium}, #{target_low})" }
      let(:excluded) { "(#{excluded_critical}, #{excluded_unknown}, #{excluded_high}, #{excluded_medium}, #{excluded_low})" }
      let(:object) do
        {
          critical: target_critical + excluded_critical,
          uknown: target_unknown + excluded_unknown,
          high: target_high + excluded_high,
          medium: target_medium + excluded_medium,
          low: target_low + excluded_low
        }.stringify_keys
      end

      let(:letter_grade_sql) { described_class.letter_grade_sql_for(target, excluded) }
      let(:letter_grade_on_db) { described_class.connection.execute(letter_grade_sql).first['letter_grade'] }
      let(:letter_grade_on_app) { described_class.letter_grade_for(object) }

      it 'matches the application layer logic' do
        expect(letter_grade_on_db).to eq(letter_grade_on_app)
      end
    end
  end

  describe '.set_latest_pipeline_with' do
    let_it_be(:pipeline) { create(:ci_pipeline) }
    let_it_be(:project) { pipeline.project }

    subject(:set_latest_pipeline) { described_class.set_latest_pipeline_with(pipeline) }

    context 'when there is already a vulnerability_statistic record available for the project of given pipeline' do
      let(:vulnerability_statistic) { create(:vulnerability_statistic, project: project) }

      it 'updates the `latest_pipeline_id` attribute of the existing record' do
        expect { set_latest_pipeline }.to change { vulnerability_statistic.reload.pipeline }.from(nil).to(pipeline)
      end
    end

    context 'when there is no vulnerability_statistic record available for the project of given pipeline' do
      it 'creates a new record with the `latest_pipeline_id` attribute is set' do
        expect { set_latest_pipeline }.to change { project.reload.vulnerability_statistic }.from(nil).to(an_instance_of(described_class))
                                      .and change { project.vulnerability_statistic&.pipeline }.from(nil).to(pipeline)
      end
    end
  end

  context 'loose foreign key on vulnerability_statistics.latest_pipeline_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:ci_pipeline) }
      let!(:model) { create(:vulnerability_statistic, pipeline: parent) }
    end
  end
end
