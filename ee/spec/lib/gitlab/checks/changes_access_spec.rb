# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::ChangesAccess, feature_category: :source_code_management do
  describe '#validate!' do
    include_context 'push rules checks context'

    let(:push_rule) { create(:push_rule, deny_delete_tag: true) }
    let(:changes) do
      [
        { oldrev: oldrev, newrev: newrev, ref: ref }
      ]
    end

    let(:changes_access) do
      described_class.new(
        changes,
        project: project,
        user_access: user_access,
        protocol: protocol,
        logger: logger
      )
    end

    subject { changes_access }

    it_behaves_like 'check ignored when push rule unlicensed'

    it 'calls push rules validators' do
      expect_next_instance_of(EE::Gitlab::Checks::PushRuleCheck) do |instance|
        expect(instance).to receive(:validate!)
      end

      subject.validate!
    end

    context 'with denylisted files check' do
      let(:push_rule) { create(:push_rule, prevent_secrets: true) }

      context 'when the repository was empty' do
        let(:project) { create(:project, :empty_repo, push_rule: push_rule) }
        let(:user) { project.first_owner }

        let(:create_file_with_secrets) do
          project.repository.create_file(user, file_path, "commit #{file_path}", message: "commit #{file_path}",
            branch_name: "master")
        end

        let(:create_readme) do
          project.repository.create_file(user, 'README', "README", message: "commit README", branch_name: "master")
        end

        let(:new_commits) do
          [project.repository.commit(create_file_with_secrets), project.repository.commit(create_readme)]
        end

        let(:oldrev) { '0000000000000000000000000000000000000000' }
        let(:newrev) { create_readme }

        before do
          allow(project.repository).to receive(:empty?).and_return(true)
        end

        context 'when file contains secrets' do
          let(:file_path) { 'aws/credentials' }

          it "returns an error if a new or renamed filed doesn't match the file name regex" do
            expect do
              subject.validate!
            end.to raise_error(Gitlab::GitAccess::ForbiddenError,
              /File name #{file_path} was prohibited by the pattern/)
          end

          context 'when feature flag "verify_push_rules_for_first_commit" is disabled' do
            before do
              stub_feature_flags(verify_push_rules_for_first_commit: false)
            end

            it 'does not raise an error' do
              expect(subject.validate!).to be_truthy
            end
          end
        end

        context 'when file is permitted' do
          let(:file_path) { 'aws/not_credentials' }

          it 'does not raise an error' do
            expect(subject.validate!).to be_truthy
          end
        end
      end
    end
  end
end
