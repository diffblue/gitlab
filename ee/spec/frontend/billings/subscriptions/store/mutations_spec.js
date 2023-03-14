import { TABLE_TYPE_DEFAULT, TABLE_TYPE_FREE, TABLE_TYPE_TRIAL } from 'ee/billings/constants';
import * as types from 'ee/billings/subscriptions/store/mutation_types';
import mutations from 'ee/billings/subscriptions/store/mutations';
import createState from 'ee/billings/subscriptions/store/state';
import { mockDataSubscription } from 'ee_jest/billings/mock_data';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

describe('EE billings subscription module mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.SET_NAMESPACE_ID, () => {
    it('sets namespaceId', () => {
      const expectedNamespaceId = 'test';

      expect(state.namespaceId).toBeNull();

      mutations[types.SET_NAMESPACE_ID](state, expectedNamespaceId);

      expect(state.namespaceId).toEqual(expectedNamespaceId);
    });
  });

  describe(types.REQUEST_SUBSCRIPTION, () => {
    beforeEach(() => {
      mutations[types.REQUEST_SUBSCRIPTION](state);
    });

    it('sets isLoadingSubscription to true', () => {
      expect(state.isLoadingSubscription).toBe(true);
    });

    it('sets hasErrorSubscription to false', () => {
      expect(state.hasErrorSubscription).toBe(false);
    });
  });

  describe(types.RECEIVE_SUBSCRIPTION_SUCCESS, () => {
    const getColumnValues = (columns) =>
      columns.reduce(
        (acc, { id, value }) => ({
          ...acc,
          [id]: value,
        }),
        {},
      );
    const getStateTableValues = (key) =>
      state.tables[key].rows.map(({ columns }) => getColumnValues(columns));

    describe.each`
      desc                            | subscription                  | tableKey
      ${'with Ultimate subscription'} | ${mockDataSubscription.gold}  | ${TABLE_TYPE_DEFAULT}
      ${'with Free plan'}             | ${mockDataSubscription.free}  | ${TABLE_TYPE_FREE}
      ${'with Ultimate trial'}        | ${mockDataSubscription.trial} | ${TABLE_TYPE_TRIAL}
    `('$desc', ({ subscription, tableKey }) => {
      beforeEach(() => {
        state.isLoadingSubscription = true;
        mutations[types.RECEIVE_SUBSCRIPTION_SUCCESS](state, subscription);
      });

      it('sets isLoadingSubscription to false', () => {
        expect(state.isLoadingSubscription).toBe(false);
      });

      it('sets plan', () => {
        const { plan } = convertObjectPropsToCamelCase(subscription, { deep: true });

        expect(state.plan).toEqual(plan);
      });

      it('sets billing information', () => {
        const { billing } = convertObjectPropsToCamelCase(subscription, { deep: true });

        expect(state.billing).toEqual(billing);
      });

      it(`updates table ${tableKey} with subscription plan`, () => {
        expect(getStateTableValues(tableKey)).toMatchSnapshot();
      });
    });
  });

  describe(types.RECEIVE_SUBSCRIPTION_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_SUBSCRIPTION_ERROR](state);
    });

    it('sets isLoadingSubscription to false', () => {
      expect(state.isLoadingSubscription).toBe(false);
    });

    it('sets hasErrorSubscription to true', () => {
      expect(state.hasErrorSubscription).toBe(true);
    });
  });
});
