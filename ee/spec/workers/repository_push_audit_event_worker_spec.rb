# frozen_string_literal: true
require 'spec_helper'

RSpec.describe RepositoryPushAuditEventWorker do
  describe '#perform' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }
    let_it_be(:changes) do
      [
        {
          'before' => '123456',
          'after' => '789012',
          'ref' => 'refs/heads/tést'
        },
        {
          'before' => '654321',
          'after' => '210987',
          'ref' => 'refs/tags/tag'
        }
      ]
    end

    subject { described_class.new.perform(changes, project.id, user.id) }

    it 'performs no operation' do
      expect(subject).to eq(nil)
    end
  end
end
