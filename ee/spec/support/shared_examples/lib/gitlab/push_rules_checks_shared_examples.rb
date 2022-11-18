# frozen_string_literal: true

RSpec.shared_examples 'check ignored when push rule unlicensed' do
  before do
    stub_licensed_features(push_rules: false)
  end

  it { is_expected.to be_truthy }
end

RSpec.shared_examples 'use predefined push rules' do
  it 'calls Project#predefined_push_rule' do
    expect(project).to receive(:predefined_push_rule).and_call_original

    begin
      subject.validate!
    rescue Gitlab::GitAccess::ForbiddenError
      # Do nothing. Rescuing in case subject.validate! raises an error. There
      # are consumers of this shared example gsherein subject.validate! will raise
      # an error, and some don't.
    end
  end
end
