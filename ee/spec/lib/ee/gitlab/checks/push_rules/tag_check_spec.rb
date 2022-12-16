# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::Checks::PushRules::TagCheck do
  include_context 'push rules checks context'

  describe '#validate!' do
    let(:push_rule) { create(:push_rule, deny_delete_tag: true) }
    let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
    let(:newrev) { '0000000000000000000000000000000000000000' }
    let(:ref) { 'refs/tags/v1.0.0' }

    it_behaves_like 'check ignored when push rule unlicensed'
    it_behaves_like 'use predefined push rules'

    it 'returns an error if the rule denies tag deletion' do
      expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, 'You cannot delete a tag')
    end

    context 'when tag is deleted in web UI' do
      let(:protocol) { 'web' }

      it 'ignores the push rule' do
        expect(subject.validate!).to be_truthy
      end
    end
  end
end
