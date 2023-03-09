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
    const componentWrapper = wrapper.findComponent(Component);
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

  describe('when the list is loading', () => {
    let module;

    beforeEach(async () => {
      module = store.state[namespace];
      module.isLoading = true;
      module.errorLoading = false;

      await nextTick();
    });

    it('passes the correct props to the dependencies table', () => {
      expectComponentWithProps(DependenciesTable, {
        dependencies: module.dependencies,
        isLoading: true,
      });
    });

    it('does not render pagination', () => {
      expect(wrapper.findComponent(Pagination).exists()).toBe(false);
    });
  });

  describe('when an error occured on load', () => {
    let module;

    beforeEach(async () => {
      module = store.state[namespace];
      module.isLoading = false;
      module.errorLoading = true;

      await nextTick();
    });

    it('passes the correct props to the dependencies table', () => {
      expectComponentWithProps(DependenciesTable, {
        dependencies: module.dependencies,
        isLoading: false,
      });
    });

    it('does not render pagination', () => {
      expect(wrapper.findComponent(Pagination).exists()).toBe(false);
    });
  });

  describe('when the list is empty', () => {
    let module;

    beforeEach(async () => {
      module = store.state[namespace];
      module.dependencies = [];
      module.pageInfo.total = 0;

      module.isLoading = false;
      module.errorLoading = false;

      await nextTick();
    });

    it('passes the correct props to the dependencies table', () => {
      expectComponentWithProps(DependenciesTable, {
        dependencies: module.dependencies,
        isLoading: false,
      });
    });

    it('does not render pagination', () => {
      expect(wrapper.findComponent(Pagination).exists()).toBe(false);
    });
  });
});
