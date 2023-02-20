# frozen_string_literal: true

RSpec.shared_examples 'link quick actions' do
  describe '/link' do
    let(:slack_link) { 'https://gitlab.slack.com/messages/eeee' }
    let(:zoom_link) { 'https://gitlab.zoom.us/j/12345' }
    let(:general_link) { 'https://gitlab.com/project/issues/1' }
    let(:invalid_link) { 'ftp://ftphost.com' }

    before do
      stub_licensed_features(issuable_resource_links: true)
    end

    context 'with valid links' do
      where(:link, :link_text, :link_text_expected, :link_type) do
        [
          [slack_link, '', 'Slack #eeee', 'slack'],
          [slack_link, 'Slack link for incident', 'Slack link for incident', 'slack'],
          [zoom_link, ' Demo zoom link', 'Demo zoom link', 'zoom'],
          [general_link, 'General link, general with command', 'General link, general with command', 'general']
        ]
      end

      with_them do
        it 'adds a resource link' do
          add_note("/link #{link} #{link_text}")

          expect(page).to have_content('Resource link added')
          expect(issue.issuable_resource_links.first.link).to eq(link)
          expect(issue.issuable_resource_links.first.link_type).to eq(link_type)
          expect(issue.issuable_resource_links.first.link_text).to eq(link_text_expected)
        end
      end
    end

    it 'cannot add an invalid zoom link' do
      add_note("/link #{invalid_link}")

      expect(page).to have_content('Failed to add a resource link')
    end
  end
end
