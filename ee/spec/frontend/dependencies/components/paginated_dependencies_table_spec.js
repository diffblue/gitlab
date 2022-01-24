import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DependenciesTable from 'ee/dependencies/components/dependencies_table.vue';
import PaginatedDependenciesTable from 'ee/dependencies/components/paginated_dependencies_table.vue';
import createStore from 'ee/dependencies/store';
import { DEPENDENCY_LIST_TYPES } from 'ee/dependencies/store/constants';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import mockDependenciesResponse from '../store/modules/list/data/mock_dependencies.json';

describe('PaginatedDependenciesTable component', () => {
  let store;
  let wrapper;
  const { namespace } = DEPENDENCY_LIST_TYPES.all;

  const factory = (props = {}) => {
    store = createStore();

    wrapper = shallowMount(PaginatedDependenciesTable, {
      store,
      propsData: { ...props },
    });
  };

  const expectComponentWithProps = (Component, props = {}) => {
    const componentWrapper = wrapper.find(Component);
    expect(componentWrapper.isVisible()).toBe(true);
    expect(componentWrapper.props()).toEqual(expect.objectContaining(props));
  };

  beforeEach(async () => {
    factory({ namespace });

    const originalDispatch = store.dispatch;
    jest.spyOn(store, 'dispatch').mockImplementation();
    originalDispatch(`${namespace}/receiveDependenciesSuccess`, {
      data: mockDependenciesResponse,
      headers: { 'X-Total': mockDependenciesResponse.dependencies.length },
    });

    await nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('passes the correct props to the dependencies table', () => {
    expectComponentWithProps(DependenciesTable, {
      dependencies: mockDependenciesResponse.dependencies,
      isLoading: store.state[namespace].isLoading,
    });
  });

  it('passes the correct props to the pagination', () => {
    expectComponentWithProps(Pagination, {
      change: wrapper.vm.fetchPage,
      pageInfo: store.state[namespace].pageInfo,
    });
  });

  it('has a fetchPage method which dispatches the correct action', () => {
    const page = 2;
    wrapper.vm.fetchPage(page);
    expect(store.dispatch).toHaveBeenCalledTimes(1);
    expect(store.dispatch).toHaveBeenCalledWith(`${namespace}/fetchDependencies`, { page });
  });

  describe.each`
    context                         | isLoading | errorLoading | isListEmpty
    ${'the list is loading'}        | ${true}   | ${false}     | ${false}
    ${'there was an error loading'} | ${false}  | ${true}      | ${false}
    ${'the list is empty'}          | ${false}  | ${false}     | ${true}
  `('given $context', ({ isLoading, errorLoading, isListEmpty }) => {
    let module;

    beforeEach(async () => {
      module = store.state[namespace];
      if (isListEmpty) {
        module.dependencies = [];
        module.pageInfo.total = 0;
      }

      module.isLoading = isLoading;
      module.errorLoading = errorLoading;

      await nextTick();
    });

    // See https://github.com/jest-community/eslint-plugin-jest/issues/229 for
    // a similar reason for disabling the rule on the next line
    // eslint-disable-next-line jest/no-identical-title
    it('passes the correct props to the dependencies table', () => {
      expectComponentWithProps(DependenciesTable, {
        dependencies: module.dependencies,
        isLoading,
      });
    });

    it('does not render pagination', () => {
      expect(wrapper.find(Pagination).exists()).toBe(false);
    });
  });
});
