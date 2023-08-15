import { GlTable, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import MembersApp from 'ee/pages/groups/saml_providers/saml_members/index.vue';
import createInitialState from 'ee/pages/groups/saml_providers/saml_members/store/state';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';

Vue.use(Vuex);

describe('SAML providers members app', () => {
  let wrapper;
  let fetchPageMock;

  const createWrapper = (state = {}) => {
    const store = new Vuex.Store({
      state: {
        ...createInitialState(),
        ...state,
      },
      actions: {
        fetchPage: fetchPageMock,
      },
    });

    wrapper = shallowMount(MembersApp, {
      store,
    });
  };

  beforeEach(() => {
    fetchPageMock = jest.fn();
  });

  describe('on mount', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('dispatches loadPage', () => {
      expect(fetchPageMock).toHaveBeenCalled();
    });

    it('renders loader', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createWrapper({
        isInitialLoadInProgress: false,
      });
    });

    it('does not render loader', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(false);
    });

    it('renders table', () => {
      expect(wrapper.findComponent(GlTable).exists()).toBe(true);
    });

    it('requests next page when pagination component performs change', async () => {
      const changeFn = wrapper.findComponent(TablePagination).props('change');
      changeFn(2);
      await nextTick();
      expect(fetchPageMock).toHaveBeenCalledWith(expect.anything(), 2);
    });
  });
});
