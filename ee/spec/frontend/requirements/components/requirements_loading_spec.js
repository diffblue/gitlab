import { GlDeprecatedSkeletonLoading as GlSkeletonLoading, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import RequirementsLoading from 'ee/requirements/components/requirements_loading.vue';

import { FilterState, mockRequirementsCount } from '../mock_data';

jest.mock('ee/requirements/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
  FilterState: {
    opened: 'OPENED',
    archived: 'ARCHIVED',
    all: 'ALL',
  },
}));

const createComponent = ({
  filterBy = FilterState.opened,
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

  afterEach(() => {
    wrapper.destroy();
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
      const loaders = wrapper
        .find('.requirements-list-loading')
        .findAllComponents(GlSkeletonLoading);

      expect(loaders).toHaveLength(2);
      expect(loaders.at(0).props('lines')).toBe(2);
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
      expect(wrapper.find('.requirements-list-loading').exists()).toBe(false);
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });
});
