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

  afterEach(() => {
    wrapper.destroy();
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

  describe.each`
    context                             | isLoading | errorLoading | isListEmpty | initialized
    ${'the list is loading'}            | ${true}   | ${false}     | ${false}    | ${false}
    ${'the list is empty (initalized)'} | ${false}  | ${false}     | ${true}     | ${true}
    ${'the list is empty'}              | ${false}  | ${false}     | ${true}     | ${false}
    ${'there was an error loading'}     | ${false}  | ${true}      | ${false}    | ${false}
  `('given $context', ({ isLoading, errorLoading, isListEmpty, initialized }) => {
    let moduleState;

    beforeEach(async () => {
      moduleState = Object.assign(store.state[namespace], {
        isLoading,
        errorLoading,
        initialized,
      });

      if (isListEmpty) {
        moduleState.licenses = [];
        moduleState.pageInfo.total = 0;
      }

      await nextTick();
    });

    // See https://github.com/jest-community/eslint-plugin-jest/issues/229 for
    // a similar reason for disabling the rule on the next line
    // eslint-disable-next-line jest/no-identical-title
    it('passes the correct props to the licenses table', () => {
      expectComponentWithProps(LicensesTable, {
        licenses: moduleState.licenses,
        isLoading,
      });
    });

    it('does not render pagination', () => {
      expect(wrapper.findComponent(Pagination).exists()).toBe(false);
    });
  });
});
