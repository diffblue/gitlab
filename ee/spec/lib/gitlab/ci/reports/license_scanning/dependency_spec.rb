# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::LicenseScanning::Dependency do
  describe 'value equality' do
    let(:set) { Set.new }

    it 'cannot add the same dependency to a set twice' do
      set.add(described_class.new(name: 'bundler'))
      set.add(described_class.new(name: 'bundler'))

      expect(set.count).to eq(1)
    end

    it { expect(described_class.new(name: 'bundler')).to eql(described_class.new(name: 'bundler')) }
  end

  describe "#blob_path_for" do
    let(:dependency) { described_class.new(name: 'rails', path: lockfile) }
    let(:lockfile) { 'Gemfile.lock' }

    context "when a project, sha and path are provided" do
      subject { dependency.blob_path_for(build.project, sha: build.sha) }

      let(:build) { build_stubbed(:ee_ci_build, :success, :license_scan_v2) }

      specify { expect(subject).to eql("/#{build.project.namespace.path}/#{build.project.name}/-/blob/#{build.sha}/#{lockfile}") }
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

      specify { expect(subject).to eql("/#{project.namespace.path}/#{project.name}/-/blob/master/#{lockfile}") }
    end
  end
end
