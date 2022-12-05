# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::ChangesAccess do
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
  end
end
