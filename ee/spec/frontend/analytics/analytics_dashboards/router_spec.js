import VueRouter from 'vue-router';
import createRouter from 'ee/analytics/analytics_dashboards/router';

describe('Dashboards list router', () => {
  const base = '/dashboard';

  it('returns a router object', () => {
    const router = createRouter(base);

    expect(router).toBeInstanceOf(VueRouter);
    expect(router.history.base).toBe(base);
  });
});
