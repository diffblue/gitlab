import VueApollo from 'vue-apollo';
import { writeInitialDataToApolloCache } from 'ee/subscriptions/buy_addons_shared/utils';
import plansQuery from 'ee/subscriptions/graphql/queries/plans.customer.query.graphql';
import { createMockClient } from 'helpers/mock_apollo_helper';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import { mockCiMinutesPlans, mockDefaultCache } from 'ee_jest/subscriptions/mock_data';

export function createMockApolloProvider(mockResponses = {}, dataset = {}) {
  const {
    plansQueryMock = jest.fn().mockResolvedValue({ data: { plans: mockCiMinutesPlans } }),
  } = mockResponses;

  const { quantity } = dataset;

  const mockDefaultClient = createMockClient();
  const mockCustomersDotClient = createMockClient([[plansQuery, plansQueryMock]]);

  const apolloProvider = new VueApollo({
    defaultClient: mockDefaultClient,
    clients: { [CUSTOMERSDOT_CLIENT]: mockCustomersDotClient },
  });

  writeInitialDataToApolloCache(apolloProvider, {
    ...mockDefaultCache,
    subscriptionQuantity: quantity,
  });

  return apolloProvider;
}
