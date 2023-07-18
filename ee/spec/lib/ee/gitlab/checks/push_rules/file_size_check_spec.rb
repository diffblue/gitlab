# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::Checks::PushRules::FileSizeCheck, feature_category: :source_code_management do
  include_context 'push rules checks context'

  let(:changes) do
    [
      # Update of existing branch
      { oldrev: oldrev, newrev: newrev, ref: ref },
      # Creation of new branch
      { newrev: newrev, ref: 'refs/heads/something' },
      # Deletion of branch
      { oldrev: oldrev, ref: 'refs/heads/deleteme' }
    ]
  end

  let(:changes_access) do
    Gitlab::Checks::ChangesAccess.new(
      changes,
      project: project,
      user_access: user_access,
      protocol: protocol,
      logger: logger
    )
  end

  subject { described_class.new(changes_access) }

  describe '#validate!' do
    let(:push_rule) { create(:push_rule, max_file_size: 1) }
    # SHA of the 2-mb-file branch
    let(:newrev)    { 'bf12d2567099e26f59692896f73ac819bae45b00' }
    let(:ref)       { 'my-branch' }

    let(:any_blob_double) { instance_double(Gitlab::Checks::FileSizeCheck::AnyOversizedBlobs, find: []) }

    it_behaves_like 'check ignored when push rule unlicensed'
    it_behaves_like 'use predefined push rules'

    it 'delegates to AnyOversizedBlobs' do
      expect(Gitlab::Checks::FileSizeCheck::AnyOversizedBlobs).to receive(:new).with(
        project: project,
        changes: changes,
        file_size_limit_megabytes: push_rule.max_file_size
      ).and_return(any_blob_double)

      subject.validate!
    end

    context 'when the file size limit is exceeded' do
      before do
        allow(Gitlab::Checks::FileSizeCheck::AnyOversizedBlobs).to receive(:new).and_return(any_blob_double)
        allow(any_blob_double).to receive(:find).and_return([instance_double(Gitlab::Git::Blob, path: 'file.bin')])
      end

      it 'returns an error if file exceeds the maximum file size' do
        expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, "File \"file.bin\" is larger than the allowed size of 1 MiB. Use Git LFS to manage this file.")
      end
    end
  end
end
