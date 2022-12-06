import VueRouter from 'vue-router';
import createAnalyticsRouter from 'ee/product_analytics/router';

describe('Product Analytics Router Spec', () => {
  it('returns a router object', () => {
    const router = createAnalyticsRouter();

    expect(router).toBeInstanceOf(VueRouter);
  });
});
