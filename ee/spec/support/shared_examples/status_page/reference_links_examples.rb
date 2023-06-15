# frozen_string_literal: true

# This shared_example requires the following variables:
# - object: The AR object
# - field: The entity field/AR attribute which contains the GFM reference
# - value: The resulting JSON value
RSpec.shared_examples 'reference links for status page' do
  let(:project) { object.project }
  let(:author) { object.author }
  let(:gfm_reference) { reference.to_reference(full: true) }

  before do
    project.add_guest(author) unless project.team.member?(author)
    project.update!(visibility_level: project_visibility)
    object.update!(field => gfm_reference)

    expect(StatusPage::Renderer)
      .to receive(:markdown)
      .at_least(:once)
      .and_call_original
  end

  shared_examples 'html reference' do
    it 'shows link anchor with HTML data attributes' do
      aggregate_failures do
        expect(value).to include(gfm_reference)
        expect(value).to include('<a ')
        expect(value).to include(reference.title)
      end
    end
  end

  shared_examples 'plain reference' do
    it 'redacts link anchor and HTML data attributes' do
      aggregate_failures do
        expect(value).to include(gfm_reference)
        expect(value).not_to include('<a ')
        expect(value).not_to include(reference.title)
      end
    end
  end

  context 'with public project' do
    let(:project_visibility) { Project::PUBLIC }

    context 'with public issue' do
      let(:reference) { create(:issue, project: project) }

      include_examples 'html reference'
    end

    context 'with confidential issue' do
      let(:reference) { create(:issue, :confidential, project: project) }

      include_examples 'plain reference'
    end
  end

  context 'with private project' do
    let(:project_visibility) { Project::PRIVATE }

    context 'with public issue' do
      let(:reference) { create(:issue, project: project) }

      include_examples 'plain reference'
    end
  end

  describe 'mentions' do
    let(:project_visibility) { Project::PUBLIC }

    shared_examples 'mention anonymization' do
      let(:anonymized_name) { 'Incident Responder' }

      it 'anonymizes mention' do
        aggregate_failures do
          expect(value).to include(anonymized_name)
          expect(value).not_to include('<a ')
          expect(value).not_to include(reference.name)
        end
      end
    end

    context 'with username' do
      let(:reference) { project.creator }

      include_examples 'mention anonymization'
    end

    context 'with arbitrary username' do
      let(:reference) do
        double(:reference, to_reference: '@non_existing_mention')
      end

      it 'shows the mention' do
        expect(value).to include(reference.to_reference)
      end
    end

    context 'with @all' do
      let(:reference) do
        double(:reference, name: 'All Project and Group Members', to_reference: '@all')
      end

      before do
        # Note: since we're testing the same reference (@all), we need to reset `field`.
        #
        # 1. `_html` attributes are only updated if the target attribute changes
        #     e.g., `description` must change to trigger an update in `description_html`
        # 2. `field`` could be an attribute that cannot be blank so use a random placeholder `:tada:`.
        object.update!(field => ":tada:")
      end

      context 'when `disable_all_mention` FF is disabled' do
        before do
          stub_feature_flags(disable_all_mention: false)

          object.update!(field => gfm_reference)
        end

        let(:anonymized_name) { 'Incident Responder' }

        it 'anonymizes mention' do
          aggregate_failures do
            expect(value).to include(anonymized_name)
            expect(value).not_to include('<a ')
            expect(value).not_to include(reference.name)
          end
        end
      end

      context 'when `disable_all_mention` FF is enabled' do
        before do
          stub_feature_flags(disable_all_mention: true)

          object.update!(field => gfm_reference)
        end

        it 'shows the mention text' do
          expect(value).to include('@all')
        end
      end
    end

    context 'with groups' do
      where(:group_visibility) do
        %i[public internal private]
      end

      with_them do
        let(:reference) { create(:group, group_visibility) }

        include_examples 'mention anonymization'
      end
    end
  end
end
