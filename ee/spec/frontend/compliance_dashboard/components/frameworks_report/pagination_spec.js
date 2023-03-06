import { GlKeysetPagination } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import { NEXT, PREV } from '~/vue_shared/components/pagination/constants';

import Pagination from 'ee/compliance_dashboard/components/frameworks_report/pagination.vue';

describe('Pagination component', () => {
  let wrapper;

  const pageInfo = {
    endCursor: 'abc',
    hasNextPage: true,
    hasPreviousPage: true,
    startCursor: 'abc',
    __typename: 'PageInfo',
  };

  const findKeysetPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findNextButton = () => wrapper.findByText(NEXT);
  const findPrevButton = () => wrapper.findByText(PREV);
  const findPageSizeSelector = () => wrapper.findComponent(PageSizeSelector);

  const createComponent = (props = {}) => {
    return extendedWrapper(
      mount(Pagination, {
        propsData: {
          ...props,
        },
      }),
    );
  };

  describe('default behavior', () => {
    beforeEach(() => {
      wrapper = createComponent({
        pageInfo,
        isLoading: false,
        perPage: 20,
      });
    });

    it('passes props to keyset pagination component', () => {
      expect(findKeysetPagination().exists()).toBe(true);
      expect(findKeysetPagination().props()).toMatchObject(
        expect.objectContaining({
          endCursor: 'abc',
          hasNextPage: true,
          hasPreviousPage: true,
          startCursor: 'abc',
          disabled: false,
          nextText: NEXT,
          prevText: PREV,
        }),
      );
    });

    it('emits event when going to next page', () => {
      findNextButton().trigger('click');

      expect(wrapper.emitted('next').length).toBe(1);
    });

    it('emits event when going to prev page', () => {
      findPrevButton().trigger('click');

      expect(wrapper.emitted('prev').length).toBe(1);
    });

    it('emits even when changing page size', () => {
      findPageSizeSelector().vm.$emit('input');

      expect(wrapper.emitted('page-size-change').length).toBe(1);
    });
  });
});
