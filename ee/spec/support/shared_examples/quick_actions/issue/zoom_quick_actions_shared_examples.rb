# frozen_string_literal: true

RSpec.shared_examples 'zoom quick actions ee' do
  let(:zoom_link) { 'https://zoom.us/j/123456789' }
  let(:invalid_zoom_link) { 'https://invalid-zoom' }

  describe '/zoom' do
    before do
      stub_licensed_features(issuable_resource_links: true)
    end

    context 'with valid zoom_meetings' do
      where(:link_text, :link_text_expected) do
        [
          ['', 'Zoom #123456789'],
          ['Demo meeting', 'Demo meeting'],
          ['Fire, fire, everything on fire', 'Fire, fire, everything on fire'],
          [' Space, fire extinguished', 'Space, fire extinguished']
        ]
      end

      with_them do
        it 'adds a Zoom link' do
          add_note("/zoom #{zoom_link} #{link_text}")

          expect(page).to have_content('Zoom meeting added')
          expect(issue.issuable_resource_links.first.link).to eq(zoom_link)
          expect(issue.issuable_resource_links.first.link_text).to eq(link_text_expected)
        end
      end
    end

    it 'cannot add an invalid zoom link' do
      add_note("/zoom #{invalid_zoom_link}")

      expect(page).to have_content('Failed to add a Zoom meeting')
      expect(page).not_to have_content(zoom_link)
    end
  end
end
