import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { GlAlert, GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IndexEntitiesSelector from 'ee/admin/application_settings/advanced_search/components/index_entities_selector.vue';
import {
  NO_RESULTS_TEXT,
  SEARCH_QUERY_TOO_SHORT,
  ENTITIES_FETCH_ERROR,
} from 'ee/admin/application_settings/advanced_search/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { entities, projectsMock } from '../mock_data';

describe('IndexEntitiesSelector', () => {
  let wrapper;
  let mockAxios;

  // Props
  const initialSelection = () => [...entities];
  const apiPath = 'apiPath';
  const toggleText = 'toggleText';
  const nameProp = 'full_path';

  // Finders
  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findGlAlert = () => wrapper.findComponent(GlAlert);

  // Helpers
  const openListbox = () => findGlCollapsibleListbox().vm.$emit('shown');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(IndexEntitiesSelector, {
      propsData: {
        selected: initialSelection(),
        apiPath,
        toggleText,
        nameProp,
        ...props,
      },
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(apiPath).reply(HTTP_STATUS_OK, projectsMock);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('initial state', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      value              | propName
      ${false}           | ${'searching'}
      ${toggleText}      | ${'toggleText'}
      ${NO_RESULTS_TEXT} | ${'noResultsText'}
    `("passes '$value' as `$propName` to `gl-collapsible-listbox`", ({ value, propName }) => {
      expect(findGlCollapsibleListbox().props(propName)).toStrictEqual(value);
    });
  });

  describe('when the listbox is opened', () => {
    const selectedItem = {
      value: String(projectsMock[2].id),
      text: projectsMock[2].full_path,
    };
    beforeEach(() => {
      createComponent();
      openListbox();
      return waitForPromises();
    });

    it('fetches the entities and passes the non-selected ones to the listbox', () => {
      expect(mockAxios.history.get).toHaveLength(1);
      expect(findGlCollapsibleListbox().props('items')).toStrictEqual([
        {
          value: String(projectsMock[2].id),
          text: projectsMock[2].full_path,
        },
      ]);
    });

    it('emits the `select` event when selecting an option and removes it from the listbox', async () => {
      findGlCollapsibleListbox().vm.$emit('select', selectedItem.value);
      await nextTick();

      expect(wrapper.emitted('select')).toStrictEqual([
        [
          {
            id: projectsMock[2].id,
            text: projectsMock[2].full_path,
          },
        ],
      ]);
    });

    it('does not attempt to re-fetch the entities when the listbox is opened again', async () => {
      openListbox();
      await waitForPromises();

      expect(mockAxios.history.get).toHaveLength(1);
    });
  });

  describe('when searching', () => {
    const searchString = 'searchString';

    beforeEach(() => {
      createComponent();
      openListbox();
      findGlCollapsibleListbox().vm.$emit('search', searchString);
      return waitForPromises();
    });

    it('fetches matching entities', () => {
      expect(mockAxios.history.get).toHaveLength(2);
      expect(mockAxios.history.get[1].params).toStrictEqual({
        search: searchString,
      });
    });

    it('sets the correct `no-results-text` prop when the search query is too short', async () => {
      findGlCollapsibleListbox().vm.$emit('search', 'a');
      await nextTick();

      expect(findGlCollapsibleListbox().props('noResultsText')).toBe(SEARCH_QUERY_TOO_SHORT);
    });
  });

  describe('when request fails', () => {
    beforeEach(() => {
      mockAxios.onGet(apiPath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      createComponent();
      openListbox();
      return waitForPromises();
    });

    it('shows an error message', () => {
      const alert = findGlAlert();

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(ENTITIES_FETCH_ERROR);
    });
  });
});
