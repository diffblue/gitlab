# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::RepositoryMenu do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: 'master') }

  describe 'File Locks' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == :file_locks } }

    context 'when licensed feature file locks is not enabled' do
      it 'does not include file locks menu item' do
        stub_licensed_features(file_locks: false)

        is_expected.to be_nil
      end
    end

    context 'when licensed feature file locks is enabled' do
      it 'includes file locks menu item' do
        stub_licensed_features(file_locks: true)

        is_expected.to be_present
      end
    end
  end
end
