# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ZentaoSerializers::IssueEntity do
  let_it_be(:zentao_integration) { create(:zentao_integration) }
  let_it_be(:project) { zentao_integration.project }

  let(:zentao_issue) do
    { id: 'story-34',
      title: 'Issue from ZenTao',
      labels: %w[Backend L1],
      pri: 3,
      openedDate: '2021-01-01T00:00:00Z',
      openedBy: {
        id: 1, account: 'admin',
        realname: 'admin',
        avatar: 'http://example.com/avatar/1',
        url: 'http://example.com/users/1'
      },
      lastEditedDate: '2021-01-02T00:00:00Z',
      lastEditedBy: 'admin',
      status: issue_status,
      url: 'http://example.com/issues/1',
      assignedTo: [
        { id: 2,
          account: 'productManager',
          realname: 'productManager',
          avatar: 'http://example.com/avatar/2',
          url: 'http://example.com/users/2' }
      ] }.deep_stringify_keys
  end

  subject { described_class.new(zentao_issue, project: project).as_json }

  context 'when status is "opened"' do
    let(:issue_status) { 'opened' }

    it 'returns the ZenTao issues attributes' do
      expected_hash = common_expected_hash.merge(
        status: 'opened', state: 'opened', closed_at: nil)

      expect(subject).to include(expected_hash)
    end
  end

  context 'when status is "closed"' do
    let(:issue_status) { 'closed' }

    it 'returns the ZenTao issues attributes' do
      expected_hash = common_expected_hash.merge(
        status: 'closed', state: 'closed', closed_at: '2021-01-02T00:00:00Z'.to_datetime)

      expect(subject).to include(expected_hash)
    end
  end

  private

  def common_expected_hash
    { id: 'story-34',
      project_id: project.id,
      title: 'Issue from ZenTao',
      created_at: '2021-01-01T00:00:00Z'.to_datetime,
      updated_at: '2021-01-02T00:00:00Z'.to_datetime,
      labels: [
        { id: 'Backend',
          title: 'Backend',
          name: 'Backend',
          color: '#0052CC',
          text_color: '#FFFFFF' },
        { id: 'L1',
          title: 'L1',
          name: 'L1',
          color: '#0052CC',
          text_color: '#FFFFFF' }
      ],
      author: { id: 1,
                name: 'admin',
                web_url: 'http://example.com/users/1',
                avatar_url: 'http://example.com/avatar/1' },
      assignees: [{ id: 2,
                    name: 'productManager',
                    web_url: 'http://example.com/users/2',
                    avatar_url: 'http://example.com/avatar/2' }],
      web_url: 'http://example.com/issues/1',
      gitlab_web_url: "/#{project.full_path}/-/integrations/zentao/issues/story-34" }
  end
end
