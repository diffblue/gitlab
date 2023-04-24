# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::LicenseScanning::Dependency, feature_category: :software_composition_analysis do
  describe 'object equality' do
    let(:attributes) { { name: 'bundler', package_manager: 'rubygems', purl_type: 'gem', version: '1.0.0' } }
    let(:dependency1) { described_class.new(attributes) }

    context 'when all fields are the same' do
      let(:dependency2) { described_class.new(attributes) }

      specify { expect(dependency1).to eql(dependency2) }

      it 'implies hashes match' do
        expect(dependency1.hash).to eql(dependency2.hash)
      end
    end

    [:name, :package_manager, :purl_type, :version].each do |field_name|
      context "when #{field_name} fields are different" do
        let(:dependency2) { described_class.new(attributes.merge(field_name => 'another-name')) }

        specify { expect(dependency1).not_to eql(dependency2) }

        it 'implies hashes do not match' do
          expect(dependency1.hash).not_to eql(dependency2.hash)
        end
      end
    end
  end

  describe 'set' do
    let(:older) { described_class.new(name: 'bundler', package_manager: 'rubygems', purl_type: 'gem', version: '1.0.0') }
    let(:clone) { described_class.new(name: 'bundler', package_manager: 'rubygems', purl_type: 'gem', version: '1.0.0') }
    let(:newer) { described_class.new(name: 'bundler', package_manager: 'rubygems', purl_type: 'gem', version: '1.0.1') }
    let(:other) { described_class.new(name: 'bundler', package_manager: 'npm', purl_type: 'npm', version: '1.0.0') }

    context 'when attempting to add an object that already exists in the set' do
      let(:set) { Set.new }

      it 'does not add a duplicate object' do
        set.add(older)
        set.add(older)
        set.add(clone)
        set.add(newer)
        set.add(other)

        expect(set).to contain_exactly(older, newer, other)
      end
    end
  end

  describe "#blob_path_for" do
    let(:dependency) { described_class.new(name: 'rails', path: lockfile) }
    let(:lockfile) { 'Gemfile.lock' }

    context "when a project, sha and path are provided" do
      subject { dependency.blob_path_for(build.project, sha: build.sha) }

      let(:build) { build_stubbed(:ee_ci_build, :success, :license_scan_v2) }

      specify { expect(subject).to eql("/#{build.project.full_path}/-/blob/#{build.sha}/#{lockfile}") }
    end

    context "when a path is not available" do
      subject { dependency.blob_path_for(build_stubbed(:project)) }

      let(:lockfile) { nil }

      specify { expect(subject).to be_nil }
    end

    context "when a project is not provided" do
      subject { dependency.blob_path_for(nil) }

      specify { expect(subject).to eql(lockfile) }
    end

    context "when a sha is not provided" do
      subject { dependency.blob_path_for(project) }

      let(:project) { build_stubbed(:project) }

      specify { expect(subject).to eql("/#{project.full_path}/-/blob/master/#{lockfile}") }
    end
  end
end
