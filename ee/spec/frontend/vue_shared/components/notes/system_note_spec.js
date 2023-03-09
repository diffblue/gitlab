import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_SERVICE_UNAVAILABLE } from '~/lib/utils/http_status';
import createStore from '~/notes/stores';
import IssueSystemNote from '~/vue_shared/components/notes/system_note.vue';

describe('system note component', () => {
  let wrapper;
  let props;
  let mock;

  const diffData = '<span class="idiff">Description</span><span class="idiff addition">Diff</span>';

  function mockFetchDiff() {
    mock.onGet('/path/to/diff').replyOnce(HTTP_STATUS_OK, diffData);
  }

  function mockDeleteDiff(statusCode = HTTP_STATUS_OK) {
    mock.onDelete('/path/to/diff/1').replyOnce(statusCode);
  }

  const findBlankBtn = () => wrapper.find('[data-testid="compare-btn"]');

  const findDescriptionVersion = () => wrapper.find('.description-version');

  const findDeleteDescriptionVersionButton = () =>
    wrapper.find('[data-testid="delete-description-version-button"]');

  beforeEach(() => {
    props = {
      note: {
        id: '1424',
        author: {
          id: 1,
          name: 'Root',
          username: 'root',
          state: 'active',
          avatar_url: 'path',
          path: '/root',
        },
        note_html: '<p dir="auto">closed</p>',
        system_note_icon_name: 'status_closed',
        created_at: '2017-08-02T10:51:58.559Z',
        description_version_id: 1,
        description_diff_path: 'path/to/diff',
        delete_description_version_path: 'path/to/diff/1',
        can_delete_description_version: true,
        description_version_deleted: false,
      },
    };

    const store = createStore();
    store.dispatch('setTargetNoteHash', `note_${props.note.id}`);

    mock = new MockAdapter(axios);

    wrapper = mount(IssueSystemNote, {
      store,
      propsData: props,
      provide: {
        glFeatures: { saveDescriptionVersions: true, descriptionDiffs: true },
      },
    });
  });

  afterEach(() => {
    mock.restore();
  });

  it('should display button to toggle description diff, description version does not display', () => {
    const button = findBlankBtn();
    expect(button.exists()).toBe(true);
    expect(button.text()).toContain('Compare with previous version');
    expect(findDescriptionVersion().exists()).toBe(false);
  });

  it('click on button to toggle description diff displays description diff with delete icon button', async () => {
    mockFetchDiff();
    expect(findDescriptionVersion().exists()).toBe(false);

    const button = findBlankBtn();
    button.trigger('click');
    await nextTick();
    await waitForPromises();
    expect(findDescriptionVersion().exists()).toBe(true);
    expect(findDescriptionVersion().html()).toContain(diffData);
    expect(
      wrapper
        .find(
          '.description-version button.delete-description-history svg[data-testid="remove-icon"]',
        )
        .exists(),
    ).toBe(true);
  });

  describe('click on delete icon button', () => {
    beforeEach(() => {
      mockFetchDiff();
      const button = findBlankBtn();
      button.trigger('click');
      return waitForPromises();
    });

    it('does not delete description diff if the delete request fails', () => {
      mockDeleteDiff(HTTP_STATUS_SERVICE_UNAVAILABLE);
      findDeleteDescriptionVersionButton().trigger('click');
      return waitForPromises().then(() => {
        expect(findDeleteDescriptionVersionButton().exists()).toBe(true);
      });
    });

    it('deletes description diff if the delete request succeeds', () => {
      mockDeleteDiff();
      findDeleteDescriptionVersionButton().trigger('click');
      return waitForPromises().then(() => {
        expect(findDeleteDescriptionVersionButton().exists()).toBe(false);
        expect(findDescriptionVersion().text()).toContain('Deleted');
      });
    });
  });
});
