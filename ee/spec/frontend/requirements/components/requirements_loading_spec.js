import { GlSkeletonLoader, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import RequirementsLoading from 'ee/requirements/components/requirements_loading.vue';
import { filterState } from 'ee/requirements/constants';

import { mockRequirementsCount } from '../mock_data';

jest.mock('~/vue_shared/issuable/list/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
}));

const createComponent = ({
  filterBy = filterState.opened,
  requirementsCount = mockRequirementsCount,
  currentPage = 1,
} = {}) =>
  shallowMount(RequirementsLoading, {
    propsData: {
      filterBy,
      currentPage,
      requirementsCount,
    },
  });

describe('RequirementsLoading', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('computed', () => {
    describe('lastPage', () => {
      it('returns number representing last page of the list', () => {
        expect(wrapper.vm.lastPage).toBe(2);
      });
    });

    describe('loaderCount', () => {
      it('returns value of DEFAULT_PAGE_SIZE when current page is not the last page total requirements are more than DEFAULT_PAGE_SIZE', () => {
        expect(wrapper.vm.loaderCount).toBe(2);
      });

      it('returns value of remainder requirements for last page when current page is the last page total requirements are more than DEFAULT_PAGE_SIZE', async () => {
        wrapper.setProps({
          currentPage: 2,
        });

        await nextTick();
        expect(wrapper.vm.loaderCount).toBe(1);
      });

      it('returns value DEFAULT_PAGE_SIZE when current page is the last page total requirements are less than DEFAULT_PAGE_SIZE', async () => {
        wrapper.setProps({
          currentPage: 1,
          requirementsCount: {
            OPENED: 1,
            ARCHIVED: 0,
            ALL: 2,
          },
        });

        await nextTick();
        expect(wrapper.vm.loaderCount).toBe(1);
      });
    });
  });

  describe('template', () => {
    it('renders gl-skeleton-loading component project has some requirements and current tab has requirements to show', () => {
      const loaders = wrapper.findAllComponents(GlSkeletonLoader);

      expect(loaders).toHaveLength(2);
      expect(loaders.at(0).attributes('lines')).toBe('2');
    });

    it('renders gl-loading-icon component project has no requirements and current tab has nothing to show', async () => {
      wrapper.setProps({
        requirementsCount: {
          OPENED: 0,
          ARCHIVED: 0,
          ALL: 0,
        },
      });

      await nextTick();
      expect(wrapper.findAllComponents(GlSkeletonLoader)).toHaveLength(0);
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });
});
