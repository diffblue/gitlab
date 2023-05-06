import { shallowMount } from '@vue/test-utils';
import { GlKeysetPagination } from '@gitlab/ui';
import WorkspacesListPagination from 'ee/remote_development/components/list/workspaces_list_pagination.vue';
import { WORKSPACES_LIST_PAGE_SIZE } from 'ee/remote_development//constants';

jest.mock('~/lib/logger');

describe('remote_development/components/list/workspaces_list_pagination.vue', () => {
  let wrapper;

  const createWrapper = ({ pageInfo = {} } = {}) => {
    wrapper = shallowMount(WorkspacesListPagination, {
      propsData: {
        pageInfo,
      },
    });
  };
  const findKeysetPagination = () => wrapper.findComponent(GlKeysetPagination);

  describe('visibility', () => {
    it.each`
      hasNextPage | hasPreviousPage | visible
      ${true}     | ${true}         | ${true}
      ${true}     | ${false}        | ${true}
      ${false}    | ${true}         | ${true}
      ${false}    | ${false}        | ${false}
    `(
      'hasNextPage=$hasNextPage, hasPreviousPage=$hasPreviousPage, visible=$visible',
      ({ hasNextPage, hasPreviousPage, visible }) => {
        createWrapper({ pageInfo: { hasNextPage, hasPreviousPage } });
        expect(findKeysetPagination().exists()).toBe(visible);
      },
    );
  });

  it.each`
    pageAction | pageInfo                                       | inputEventData
    ${'prev'}  | ${{ startCursor: 'start', hasNextPage: true }} | ${{ before: 'start', first: WORKSPACES_LIST_PAGE_SIZE }}
    ${'next'}  | ${{ endCursor: 'end', hasNextPage: true }}     | ${{ after: 'end', first: WORKSPACES_LIST_PAGE_SIZE }}
  `(
    '$pageAction event with $pageInfo triggers input event with $inputEventData',
    ({ pageAction, pageInfo, inputEventData }) => {
      createWrapper({ pageInfo });

      findKeysetPagination().vm.$emit(pageAction);

      expect(wrapper.emitted('input')).toEqual([[inputEventData]]);
    },
  );
});
