import { GlSkeletonLoader } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount } from '@vue/test-utils';
import WorkItemSystemNote from '~/work_items/components/notes/system_note.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import axios from '~/lib/utils/axios_utils';
import { workItemSystemNoteWithMetadata } from 'jest/work_items/mock_data';
import { HTTP_STATUS_OK, HTTP_STATUS_SERVICE_UNAVAILABLE } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockDirective } from 'helpers/vue_mock_directive';

jest.mock('~/behaviors/markdown/render_gfm');

describe('EE Work item system note', () => {
  let wrapper;
  let mock;

  const diffData = '<span class="idiff">Description</span><span class="idiff addition">Diff</span>';

  function mockFetchDiff() {
    mock
      .onGet(workItemSystemNoteWithMetadata.systemNoteMetadata.descriptionVersion.diffPath)
      .replyOnce(HTTP_STATUS_OK, diffData);
  }

  function mockDeleteDiff(statusCode = HTTP_STATUS_OK) {
    mock
      .onDelete(workItemSystemNoteWithMetadata.systemNoteMetadata.descriptionVersion.deletePath)
      .replyOnce(statusCode);
  }

  const findComparePreviousVersionButton = () => wrapper.find('[data-testid="compare-btn"]');
  const findDescriptionVersion = () => wrapper.find('[data-testid="description-version-diff"]');
  const findDescriptionVersionDeleteButton = () =>
    wrapper.find('[data-testid="delete-description-version-button"]');
  const findDescriptionVersionLoadingVersion = () => wrapper.findComponent(GlSkeletonLoader);

  const createComponent = ({ note = workItemSystemNoteWithMetadata } = {}) => {
    mock = new MockAdapter(axios);

    wrapper = shallowMount(WorkItemSystemNote, {
      propsData: {
        note,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        NoteHeader,
      },
      slots: {
        'extra-controls':
          '<gl-button data-testid="compare-btn">Compare with previous version</gl-button>',
      },
    });
  };

  afterEach(() => {
    mock.restore();
  });

  describe('Description version history', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should display button to toggle description diff, description version does not display', () => {
      expect(findComparePreviousVersionButton().exists()).toBe(true);
      expect(findComparePreviousVersionButton().text()).toContain('Compare with previous version');
      expect(findDescriptionVersion().exists()).toBe(false);
    });

    it('click on button to toggle description diff displays description diff with delete icon button', async () => {
      mockFetchDiff();
      expect(findDescriptionVersion().exists()).toBe(false);

      await findComparePreviousVersionButton().vm.$emit('click');
      expect(findDescriptionVersionLoadingVersion().exists()).toBe(true);
      await waitForPromises();
      expect(findDescriptionVersion().exists()).toBe(true);
      expect(findDescriptionVersion().html()).toContain(diffData);
      expect(findDescriptionVersionDeleteButton().exists()).toBe(true);
    });

    describe('Delete version history', () => {
      beforeEach(() => {
        mockFetchDiff();
        findComparePreviousVersionButton().vm.$emit('click');
        return waitForPromises();
      });

      it('does not delete description diff if the delete request fails', async () => {
        mockDeleteDiff(HTTP_STATUS_SERVICE_UNAVAILABLE);

        findDescriptionVersionDeleteButton().vm.$emit('click');
        await waitForPromises();

        expect(findDescriptionVersionDeleteButton().exists()).toBe(true);
      });

      it('deletes description diff if the delete request succeeds', async () => {
        mockDeleteDiff();

        findDescriptionVersionDeleteButton().vm.$emit('click');
        await waitForPromises();

        expect(findDescriptionVersion().text()).toContain('Deleted');
      });
    });
  });
});
