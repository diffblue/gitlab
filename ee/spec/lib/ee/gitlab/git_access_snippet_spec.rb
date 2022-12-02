# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::GitAccessSnippet do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:snippet) { create(:project_snippet, :public, :repository, project: project) }

  let(:actor) { :geo }
  let(:authentication_abilities) { [:read_project, :download_code, :push_code] }

  subject(:access) { described_class.new(actor, snippet, protocol, authentication_abilities: authentication_abilities) }

  describe '#check' do
    subject { access.check('git-receive-pack', ::Gitlab::GitAccess::ANY) }

    where(:protocol_name) do
      %w(ssh web http https)
    end

    with_them do
      let(:protocol) { protocol_name }

      it { is_expected.to be_a(::Gitlab::GitAccessResult::Success) }
    end
  end
end
