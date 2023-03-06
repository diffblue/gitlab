import { produce } from 'immer';
import { merge } from 'lodash';
import Api from 'ee/api';
import * as SubscriptionsApi from 'ee/api/subscriptions_api';
import { ERROR_FETCHING_COUNTRIES, ERROR_FETCHING_STATES } from 'ee/subscriptions/constants';
import {
  COUNTRY_TYPE,
  STATE_TYPE,
  CI_MINUTES_PER_PACK,
  I18N_CI_MINUTES_PRODUCT_LABEL,
  I18N_CI_MINUTES_PRODUCT_UNIT,
  I18N_STORAGE_PRODUCT_LABEL,
  I18N_STORAGE_PRODUCT_UNIT,
  STORAGE_PER_PACK,
} from 'ee/subscriptions/buy_addons_shared/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import { createAlert } from '~/alert';

const planCode = {
  CI_1000_MINUTES_PLAN: 'ci_minutes',
  STORAGE_PLAN: 'storage',
};

const planData = {
  [planCode.CI_1000_MINUTES_PLAN]: {
    hasExpiration: false,
    isAddon: true,
    label: I18N_CI_MINUTES_PRODUCT_LABEL,
    productUnit: I18N_CI_MINUTES_PRODUCT_UNIT,
    quantityPerPack: CI_MINUTES_PER_PACK,
  },
  [planCode.STORAGE_PLAN]: {
    hasExpiration: true,
    isAddon: true,
    label: I18N_STORAGE_PRODUCT_LABEL,
    productUnit: I18N_STORAGE_PRODUCT_UNIT,
    quantityPerPack: STORAGE_PER_PACK,
  },
};

// NOTE: These resolvers are temporary and will be removed in the future.
// See https://gitlab.com/gitlab-org/gitlab/-/issues/321643
export const gitLabResolvers = {
  Query: {
    countries: () => {
      return Api.fetchCountries()
        .then(({ data }) =>
          data.map(([name, alpha2, flag, internationalDialCode]) => ({
            name,
            id: alpha2,
            flag,
            internationalDialCode,
            __typename: COUNTRY_TYPE,
          })),
        )
        .catch(() => createAlert({ message: ERROR_FETCHING_COUNTRIES }));
    },
    states: (_, { countryId }) => {
      return Api.fetchStates(countryId)
        .then(({ data }) => {
          return Object.entries(data).map(([key, value]) => ({
            id: value,
            name: key,
            __typename: STATE_TYPE,
          }));
        })
        .catch(() => createAlert({ message: ERROR_FETCHING_STATES }));
    },
  },
  Mutation: {
    purchaseMinutes: (_, { groupId, customer, subscription }) => {
      return SubscriptionsApi.createSubscription(groupId, customer, subscription);
    },
    updateState: (_, { input }, { cache }) => {
      const oldState = cache.readQuery({ query: stateQuery });
      const state = produce(oldState, (draftState) => {
        merge(draftState, input);
      });
      cache.writeQuery({ query: stateQuery, data: state });
    },
  },
};

export const customersDotResolvers = {
  Plan: {
    hasExpiration: ({ code }) => planData[code]?.hasExpiration,
    isAddon: ({ code }) => planData[code]?.isAddon,
    label: ({ code }) => planData[code]?.label,
    productUnit: ({ code }) => planData[code]?.productUnit,
    quantityPerPack: ({ code }) => planData[code]?.quantityPerPack,
  },
};
