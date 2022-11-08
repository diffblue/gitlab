# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Quality::Seeders::Vulnerabilities do
  let_it_be_with_reload(:project) { create(:project) }

  subject(:seed) { described_class.new(project).seed! }

  context 'when project has members' do
    it 'creates expected number of vulnerabilities' do
      expect { seed }.to change(Vulnerability, :count).by(30)
    end
  end

  context 'when project has no members' do
    before do
      project.users.delete_all
    end

    it 'does not create vulnerabilities on project' do
      expect { seed }.not_to change(Vulnerability, :count)
    end
  end
end
