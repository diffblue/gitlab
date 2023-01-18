import VueRouter from 'vue-router';
import createAnalyticsRouter from 'ee/product_analytics/router';

describe('Product Analytics Router Spec', () => {
  const base = '/dashboard';

  it('returns a router object', () => {
    const router = createAnalyticsRouter(base);

    expect(router).toBeInstanceOf(VueRouter);
    expect(router.history.base).toBe(base);
  });
});
