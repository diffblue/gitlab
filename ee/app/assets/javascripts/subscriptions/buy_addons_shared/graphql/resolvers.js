import { produce } from 'immer';
import { merge } from 'lodash';
import Api from 'ee/api';
import * as SubscriptionsApi from 'ee/api/subscriptions_api';
import { ERROR_FETCHING_COUNTRIES, ERROR_FETCHING_STATES } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import createFlash from '~/flash';

// NOTE: These resolvers are temporary and will be removed in the future.
// See https://gitlab.com/gitlab-org/gitlab/-/issues/321643
export const resolvers = {
  Query: {
    countries: () => {
      return Api.fetchCountries()
        .then(({ data }) =>
          data.map(([name, alpha2]) =>
            // eslint-disable-next-line @gitlab/require-i18n-strings
            ({ name, id: alpha2, __typename: 'Country' }),
          ),
        )
        .catch(() => createFlash({ message: ERROR_FETCHING_COUNTRIES }));
    },
    states: (_, { countryId }) => {
      return Api.fetchStates(countryId)
        .then(({ data }) => {
          return Object.entries(data).map(([key, value]) => ({
            id: value,
            name: key,
            // eslint-disable-next-line @gitlab/require-i18n-strings
            __typename: 'State',
          }));
        })
        .catch(() => createFlash({ message: ERROR_FETCHING_STATES }));
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
