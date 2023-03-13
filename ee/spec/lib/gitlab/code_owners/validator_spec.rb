# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CodeOwners::Validator, feature_category: :source_code_management do
  include FakeBlobHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }

  let(:codeowner_content) do
    <<~CODEOWNERS
    docs/* @documentation-owner
    docs/CODEOWNERS @owner-1 owner2@gitlab.org @owner-3 @documentation-owner
    spec/* @test-owner @test-group @test-group/nested-group
    CODEOWNERS
  end

  let!(:owner_1) { create(:user, username: 'owner-1') }
  let!(:email_owner) { create(:user, username: 'owner-2') }
  let!(:owner_3) { create(:user, username: 'owner-3') }
  let!(:documentation_owner) { create(:user, username: 'documentation-owner') }
  let!(:test_owner) { create(:user, username: 'test-owner') }
  let(:codeowner_blob) { fake_blob(path: 'CODEOWNERS', data: codeowner_content) }
  let(:paths) { 'docs/CODEOWNERS' }

  subject(:validator) { described_class.new(project, 'with-codeowners', paths) }

  before do
    project.add_developer(owner_1)
    project.add_developer(email_owner)
    project.add_developer(documentation_owner)
    project.add_developer(test_owner)

    create(:email, user: email_owner, email: 'owner2@gitlab.org')

    allow(project.repository).to receive(:code_owners_blob).and_return(codeowner_blob)
  end

  shared_examples_for "finds no errors" do
    it "returns nil" do
      expect(subject.execute).to be_nil
    end
  end

  describe "#execute" do
    context "when the branch does not require code owner approval" do
      before do
        expect(project).to receive(:branch_requires_code_owner_approval?)
        .and_return(false)
      end

      context "when paths match entries in the codeowners file" do
        it_behaves_like "finds no errors"
      end

      context "when paths do not match entries in the codeowners file" do
        let(:paths) { "not/a/matching/path" }

        it_behaves_like "finds no errors"
      end
    end

    context "when the branch requires code owner approval" do
      before do
        expect(project).to receive(:branch_requires_code_owner_approval?)
        .and_return(true)
      end

      context "when paths match entries in the codeowners file" do
        it "returns an error message" do
          expect(subject.execute).to include("Pushes to protected branches")
        end
      end

      context "when paths do not match entries in the codeowners file" do
        let(:paths) { "not/a/matching/path" }

        it_behaves_like "finds no errors"
      end
    end
  end
end
