# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Fuzzing::Coverage::Corpus, type: :model do
  let(:corpus) { create(:corpus) }

  subject { corpus }

  describe 'associations' do
    it { is_expected.to belong_to(:package).class_name('Packages::Package') }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validate' do
    describe 'project_same_as_package_project' do
      let(:package_2) { create(:package) }

      subject(:corpus) { build(:corpus, package: package_2) }

      it 'raises the error on adding the package of a different project' do
        expect { corpus.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Package should belong to the associated project')
      end
    end
  end
end
