# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::JiraSerializers::IssueDetailEntity do
  include JiraServiceHelper

  let_it_be(:project) { create(:project) }
  let_it_be(:jira_integration) { create(:jira_integration, project: project, url: 'http://jira.com', api_url: 'http://api.jira.com') }

  let(:reporter) do
    {
      'displayName' => 'reporter',
      'avatarUrls' => { '48x48' => 'http://reporter.avatar' },
      'name' => 'reporter@reporter.com'
    }
  end

  let(:assignee) do
    {
      'displayName' => 'assignee',
      'avatarUrls' => { '48x48' => 'http://assignee.avatar' },
      'name' => 'assignee@assignee.com'
    }
  end

  let(:comment_author) do
    {
      'displayName' => 'comment_author',
      'avatarUrls' => { '48x48' => 'http://comment_author.avatar' },
      'name' => 'comment@author.com'
    }
  end

  let(:jira_issue) do
    double(
      summary: 'Title',
      renderedFields: {
        'description' => '<p>Description</p>',
        'comment' => {
          'comments' => [
            {
              'body' => '<p>Comment</p>'
            }
          ]
        }
      },
      created: '2020-06-25T15:39:30.000+0000',
      updated: '2020-06-26T15:38:32.000+0000',
      duedate: '2020-06-27T15:40:30.000+0000',
      resolutiondate: '2020-06-27T13:23:51.000+0000',
      labels: ['backend'],
      fields: {
        'reporter' => reporter,
        'assignee' => assignee,
        'comment' => {
          'comments' => [
            {
              'id' => '10022',
              'author' => comment_author,
              'body' => '<p>Comment</p>',
              'created' => '2020-06-25T15:50:00.000+0000',
              'updated' => '2020-06-25T15:51:00.000+0000'
            }
          ]
        }
      },
      project: double(key: 'GL'),
      key: 'GL-5',
      status: double(name: 'To Do')
    )
  end

  subject { described_class.new(jira_issue, project: project).as_json }

  it 'returns the Jira issues attributes' do
    expect(subject).to include(
      project_id: project.id,
      title: 'Title',
      description_html: "<p dir=\"auto\">Description</p>",
      created_at: '2020-06-25T15:39:30.000+0000'.to_datetime.utc,
      updated_at: '2020-06-26T15:38:32.000+0000'.to_datetime.utc,
      due_date: '2020-06-27T15:40:30.000+0000'.to_datetime.utc,
      closed_at: '2020-06-27T13:23:51.000+0000'.to_datetime.utc,
      status: 'To Do',
      state: 'closed',
      labels: [
        {
          id: 'backend',
          title: 'backend',
          name: 'backend',
          color: '#0052CC',
          text_color: '#FFFFFF'
        }
      ],
      author: hash_including(
        name: 'reporter',
        avatar_url: 'http://reporter.avatar'
      ),
      assignees: [
        hash_including(
          name: 'assignee',
          avatar_url: 'http://assignee.avatar'
        )
      ],
      web_url: 'http://jira.com/browse/GL-5',
      references: { relative: 'GL-5' },
      external_tracker: 'jira',
      comments: [
        hash_including(
          id: '10022',
          author: hash_including(
            name: 'comment_author',
            avatar_url: 'http://comment_author.avatar'
          ),
          body_html: "<p dir=\"auto\">Comment</p>",
          created_at: '2020-06-25T15:50:00.000+0000'.to_datetime.utc,
          updated_at: '2020-06-25T15:51:00.000+0000'.to_datetime.utc
        )
      ]
    )
  end

  context 'with Jira Server configuration' do
    it 'returns the Jira Server profile URL' do
      expect(subject[:author]).to include(web_url: 'http://jira.com/secure/ViewProfile.jspa?name=reporter%40reporter.com')
      expect(subject[:assignees].first).to include(web_url: 'http://jira.com/secure/ViewProfile.jspa?name=assignee%40assignee.com')
      expect(subject[:comments].first[:author]).to include(web_url: 'http://jira.com/secure/ViewProfile.jspa?name=comment%40author.com')
    end

    context 'with only url' do
      before do
        stub_jira_integration_test
        jira_integration.update!(api_url: nil, password: 'password')
      end

      it 'returns URLs with the web url' do
        expect(subject[:author]).to include(web_url: 'http://jira.com/secure/ViewProfile.jspa?name=reporter%40reporter.com')
        expect(subject[:web_url]).to eq('http://jira.com/browse/GL-5')
      end
    end
  end

  context 'with Jira Cloud configuration' do
    before do
      reporter['accountId'] = '12345'
      assignee['accountId'] = '67890'
      comment_author['accountId'] = '54321'
    end

    it 'returns the Jira Cloud profile URL' do
      expect(subject[:author]).to include(web_url: 'http://jira.com/people/12345')
      expect(subject[:assignees].first).to include(web_url: 'http://jira.com/people/67890')
      expect(subject[:comments].first[:author]).to include(web_url: 'http://jira.com/people/54321')
    end
  end

  context 'without assignee' do
    let(:assignee) { nil }

    it 'returns an empty array' do
      expect(subject).to include(assignees: [])
    end
  end

  context 'without labels' do
    before do
      allow(jira_issue).to receive(:labels).and_return([])
    end

    it 'returns an empty array' do
      expect(subject).to include(labels: [])
    end
  end

  context 'without resolution date' do
    before do
      allow(jira_issue).to receive(:resolutiondate).and_return(nil)
    end

    it "returns 'Open' state" do
      expect(subject).to include(state: 'opened')
    end
  end
end
