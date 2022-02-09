# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Fuzzing::Coverage::Corpus, type: :model do
  subject(:corpus) { create(:corpus) }

  describe 'associations' do
    it { is_expected.to belong_to(:package).class_name('Packages::Package') }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validate' do
    describe 'project_same_as_package_project' do
      let(:package) { create(:generic_package, :with_zip_file) }

      subject(:corpus) { build(:corpus, package: package) }

      it 'raises the error on adding the package of a different project' do
        expect { corpus.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Package should belong to the associated project')
      end
    end

    describe 'package_with_package_file' do
      let(:package) { create(:package) }

      subject(:corpus) { build(:corpus, package: package, project: package.project) }

      context 'without a package file associated to the package' do
        it 'raises the error' do
          expect { corpus.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Package should have an associated package file')
        end
      end

      context 'with a package file associated to the package' do
        before do
          create(:package_file, :generic_zip, package: package)
        end

        it 'saves the record successfully' do
          expect(corpus.save).to be true
        end
      end
    end

    describe 'validate_file_format' do
      let(:xml_package_file) { create(:package_file, :xml) }
      let(:package) { xml_package_file.package }

      subject(:corpus) { build(:corpus, package: package, project: package.project) }

      context 'with an invalid last package file' do
        it 'raises the error on adding the package file with different format' do
          expect { corpus.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Package format is not supported')
        end
      end

      context 'with a valid last package file' do
        before do
          create(:package_file, :generic_zip, package: package)
        end

        it 'saves the record successfully' do
          expect(corpus.save).to be true
        end
      end
    end
  end

  describe 'validates' do
    it { is_expected.to validate_uniqueness_of(:package_id) }
  end

  describe 'scopes' do
    describe '.by_project_id_and_status_hidden' do
      subject(:find_corpuses) { described_class.by_project_id_and_status_hidden(corpus.package.project_id) }

      context 'with another_corpus having different project_id' do
        it 'includes the correct records' do
          another_corpus = create(:corpus)

          aggregate_failures do
            expect(find_corpuses).to include(corpus)
            expect(find_corpuses).not_to include(another_corpus)
          end
        end
      end

      context "with another_corpus having same project with different status apart from hidden" do
        before do
          corpus.package.update!(status: :pending_destruction)
        end

        it 'includes the correct records' do
          expect(find_corpuses).not_to include(corpus)
        end
      end
    end
  end
end
