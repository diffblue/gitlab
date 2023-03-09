import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DetectedLicensesTable from 'ee/license_compliance/components/detected_licenses_table.vue';
import LicensesTable from 'ee/license_compliance/components/licenses_table.vue';
import createStore from 'ee/license_compliance/store';
import { LICENSE_LIST } from 'ee/license_compliance/store/constants';
import { toLicenseObject } from 'ee/license_compliance/utils/mappers';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import mockLicensesResponse from '../store/modules/list/data/mock_licenses.json';

jest.mock('lodash/uniqueId', () => () => 'fakeUniqueId');

describe('DetectedLicenesTable component', () => {
  const namespace = LICENSE_LIST;

  let store;
  let wrapper;

  const factory = () => {
    store = createStore();

    wrapper = shallowMount(DetectedLicensesTable, {
      store,
    });
  };

  const expectComponentWithProps = (Component, props = {}) => {
    const componentWrapper = wrapper.findComponent(Component);
    expect(componentWrapper.isVisible()).toBe(true);
    expect(componentWrapper.props()).toEqual(expect.objectContaining(props));
  };

  beforeEach(async () => {
    factory();

    store.dispatch(`${namespace}/receiveLicensesSuccess`, {
      data: mockLicensesResponse,
      headers: { 'X-Total': mockLicensesResponse.licenses.length },
    });

    jest.spyOn(store, 'dispatch').mockImplementation();

    await nextTick();
  });

  it('passes the correct props to the licenses table', () => {
    expectComponentWithProps(LicensesTable, {
      licenses: mockLicensesResponse.licenses.map(toLicenseObject),
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
    expect(store.dispatch).toHaveBeenCalledWith(`${namespace}/fetchLicenses`, { page });
  });

  describe('when the list is loading', () => {
    let moduleState;

    beforeEach(async () => {
      moduleState = Object.assign(store.state[namespace], {
        isLoading: true,
        errorLoading: false,
        initialized: false,
      });

      await nextTick();
    });

    it('passes the correct props to the licenses table', () => {
      expectComponentWithProps(LicensesTable, {
        licenses: moduleState.licenses,
        isLoading: true,
      });
    });

    it('does not render pagination', () => {
      expect(wrapper.findComponent(Pagination).exists()).toBe(false);
    });
  });

  describe('when the list is empty', () => {
    describe('and initialized', () => {
      let moduleState;

      beforeEach(async () => {
        moduleState = Object.assign(store.state[namespace], {
          isLoading: false,
          errorLoading: false,
          initialized: true,
        });

        moduleState.licenses = [];
        moduleState.pageInfo.total = 0;

        await nextTick();
      });

      it('passes the correct props to the licenses table', () => {
        expectComponentWithProps(LicensesTable, {
          licenses: moduleState.licenses,
          isLoading: false,
        });
      });

      it('does not render pagination', () => {
        expect(wrapper.findComponent(Pagination).exists()).toBe(false);
      });
    });

    describe('and not initialized', () => {
      let moduleState;

      beforeEach(async () => {
        moduleState = Object.assign(store.state[namespace], {
          isLoading: false,
          errorLoading: false,
          initialized: false,
        });

        moduleState.licenses = [];
        moduleState.pageInfo.total = 0;

        await nextTick();
      });

      it('passes the correct props to the licenses table', () => {
        expectComponentWithProps(LicensesTable, {
          licenses: moduleState.licenses,
          isLoading: false,
        });
      });

      it('does not render pagination', () => {
        expect(wrapper.findComponent(Pagination).exists()).toBe(false);
      });
    });
  });

  describe('there was an error loading', () => {
    let moduleState;

    beforeEach(async () => {
      moduleState = Object.assign(store.state[namespace], {
        isLoading: false,
        errorLoading: true,
        initialized: false,
      });

      await nextTick();
    });

    it('passes the correct props to the licenses table', () => {
      expectComponentWithProps(LicensesTable, {
        licenses: moduleState.licenses,
        isLoading: false,
      });
    });

    it('does not render pagination', () => {
      expect(wrapper.findComponent(Pagination).exists()).toBe(false);
    });
  });
});
