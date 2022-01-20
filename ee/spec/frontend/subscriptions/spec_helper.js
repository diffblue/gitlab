import VueApollo from 'vue-apollo';
import { writeInitialDataToApolloCache } from 'ee/subscriptions/buy_addons_shared/utils';
import plansQuery from 'ee/subscriptions/graphql/queries/plans.customer.query.graphql';
import orderPreviewQuery from 'ee/subscriptions/graphql/queries/order_preview.customer.query.graphql';
import { createMockClient } from 'helpers/mock_apollo_helper';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import { mockDefaultCache, mockOrderPreview } from 'ee_jest/subscriptions/mock_data';
import { customersDotResolvers } from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';

export function createMockApolloProvider(mockResponses = {}, dataset = {}) {
  const {
    plansQueryMock,
    orderPreviewQueryMock = jest
      .fn()
      .mockResolvedValue({ data: { orderPreview: mockOrderPreview } }),
  } = mockResponses;

  const { quantity } = dataset;

  const mockDefaultClient = createMockClient();
  const mockCustomersDotClient = createMockClient(
    [
      [plansQuery, plansQueryMock],
      [orderPreviewQuery, orderPreviewQueryMock],
    ],
    customersDotResolvers,
  );

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
