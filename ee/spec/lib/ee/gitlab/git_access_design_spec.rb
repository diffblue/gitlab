# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::GitAccessDesign do
  include DesignManagementTestHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }

  let(:actor) { :geo }

  subject(:access) do
    described_class.new(actor, project, protocol, authentication_abilities: [:read_project, :download_code, :push_code])
  end

  describe '#check' do
    subject { access.check('git-receive-pack', ::Gitlab::GitAccess::ANY) }

    before do
      enable_design_management
    end

    where(:protocol_name) do
      %w(ssh web http https)
    end

    with_them do
      let(:protocol) { protocol_name }

      it { is_expected.to be_a(::Gitlab::GitAccessResult::Success) }
    end
  end
end
