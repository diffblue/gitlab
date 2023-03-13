# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CodeOwners::Loader, feature_category: :source_code_management do
  include FakeBlobHelpers
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }

  subject(:loader) { described_class.new(project, 'with-codeowners', paths) }

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

  before do
    project.add_developer(owner_1)
    project.add_developer(email_owner)
    project.add_developer(documentation_owner)
    project.add_developer(test_owner)

    create(:email, :confirmed, user: email_owner, email: 'owner2@gitlab.org')

    allow(project.repository).to receive(:code_owners_blob).and_return(codeowner_blob)
  end

  describe '#entries' do
    let(:expected_entry) { Gitlab::CodeOwners::Entry.new('docs/CODEOWNERS', '@owner-1 owner2@gitlab.org @owner-3 @documentation-owner') }
    let(:first_entry) { loader.entries.first }

    it 'returns entries for the matched line' do
      expect(loader.entries).to contain_exactly(expected_entry)
    end

    it 'only calls out to the repository once' do
      expect(project.repository).to receive(:code_owners_blob).once

      2.times { loader.entries }
    end

    it 'loads all users that are members of the project into the entry' do
      expect(first_entry.users).to contain_exactly(owner_1, email_owner, documentation_owner)
    end

    it 'does not load non members of the project into the entry' do
      expect(first_entry.users).not_to include(owner_3)
    end

    it 'loads group members of the project into the entry' do
      group.add_developer(owner_3)

      expect(first_entry.users).to include(owner_3)
    end

    context 'for multiple paths' do
      let(:project) { create(:project, :public, namespace: group) }
      let(:paths) { ['docs/CODEOWNERS', 'spec/loader_spec.rb', 'spec/entry_spec.rb'] }

      it 'loads 2 entries' do
        other_entry = Gitlab::CodeOwners::Entry.new('spec/*', '@test-owner @test-group @test-group/nested-group')

        expect(loader.entries).to contain_exactly(expected_entry, other_entry)
      end

      it 'performs 8 queries for users and groups' do
        test_group = create(:group, path: 'test-group')
        test_group.add_developer(create(:user))

        another_group = create(:group, parent: test_group, path: 'nested-group')
        another_group.add_developer(create(:user))

        create(:project_group_link, project: project, group: test_group)
        create(:project_group_link, project: project, group: another_group)

        # - 2 queries for users
        # - 1 for the emails to later divide them across the entries
        # - 2 for groups with joined routes and users
        # - 3 for loading the users for the parent group(s)
        #
        expect { loader.entries }.not_to exceed_query_limit(8)
      end
    end

    context 'group as a code owner' do
      let(:paths) { ['spec/loader_spec.rb'] }
      let(:expected_entry) { Gitlab::CodeOwners::Entry.new('spec/*', '@test-owner @test-group @test-group/nested-group') }

      it 'loads group members as code owners' do
        test_group = create(:group, path: 'test-group')
        create(:project_group_link, project: project, group: test_group)

        group_user = create(:user)

        test_group.add_developer(group_user)
        test_group.add_developer(test_owner)

        expect(loader.entries).to contain_exactly(expected_entry)
        expect(loader.members).to contain_exactly(group_user, test_owner)

        entry = loader.entries.first
        expect(entry.groups).to contain_exactly(test_group)
      end
    end

    context 'with the request store', :request_store do
      it 'only calls out to the repository once' do
        expect(project.repository).to receive(:code_owners_blob).once

        2.times { loader.entries }
      end

      it 'only processes the file once' do
        code_owners_file = loader.__send__(:code_owners_file)

        expect(code_owners_file).to receive(:get_parsed_data).once.and_call_original

        2.times { loader.entries }
      end
    end
  end

  describe '#members' do
    shared_examples_for "returns users for passed path" do
      it "returns users mentioned for the passed path do" do
        expect(loader.members).to contain_exactly(owner_1, email_owner, documentation_owner)
      end
    end

    context "non-sectional codeowners_content" do
      it_behaves_like "returns users for passed path"
    end

    context "when codeowners_content contains sections" do
      let(:codeowner_content) do
        <<~CODEOWNERS
        [Documentation]
        docs/* @documentation-owner
        docs/CODEOWNERS @owner-1 owner2@gitlab.org @owner-3 @documentation-owner
        [Testing]
        spec/* @test-owner @test-group @test-group/nested-group
        CODEOWNERS
      end

      it_behaves_like "returns users for passed path"
    end
  end

  describe "#code_owners_path" do
    context "when the file exists" do
      it "returns the path to the code_owners file" do
        expect(loader.code_owners_path).to eq("CODEOWNERS")
      end
    end

    context "when the file does not exist" do
      let(:codeowner_blob) { nil }

      it "returns nil" do
        expect(loader.code_owners_path).to be_nil
      end
    end
  end

  describe '#code_owners_sections' do
    subject { loader.code_owners_sections }

    context 'when CODEOWNERS does not have sections' do
      it { is_expected.to match_array(['codeowners']) }
    end

    context 'when CODEOWNERS contains sections' do
      let(:codeowner_content) do
        <<~CODEOWNERS
        [Documentation]
        docs/* @documentation-owner
        docs/CODEOWNERS @owner-1 owner2@gitlab.org @owner-3 @documentation-owner
        [Testing]
        spec/* @test-owner @test-group @test-group/nested-group
        CODEOWNERS
      end

      it { is_expected.to match_array(%w[codeowners Documentation Testing]) }
    end
  end

  describe '#empty_code_owners?' do
    context 'when file does not exist' do
      let(:codeowner_blob) { nil }

      it 'returns true' do
        expect(loader.empty_code_owners?).to eq(true)
      end
    end

    context 'when file is empty' do
      let(:codeowner_content) { '' }

      it 'returns true' do
        expect(loader.empty_code_owners?).to eq(true)
      end
    end

    context 'when file content exists' do
      it 'returns false' do
        expect(loader.empty_code_owners?).to eq(false)
      end
    end
  end
end
