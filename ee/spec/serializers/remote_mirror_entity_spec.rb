# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteMirrorEntity, feature_category: :source_code_management do
  let(:remote_mirror) { build(:remote_mirror) }
  let(:entity) { described_class.new(remote_mirror) }

  subject { entity.as_json }

  it 'exposes mirror_branch_regex' do
    is_expected.to include(
      :only_protected_branches, :mirror_branch_regex
    )
  end
end
