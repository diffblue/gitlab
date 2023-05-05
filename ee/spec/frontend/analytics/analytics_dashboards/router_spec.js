import createRouter from 'ee/analytics/analytics_dashboards/router';

describe('Dashboards list router', () => {
  const base = '/dashboard';

  it('returns a router object', () => {
    const router = createRouter(base);
    // vue-router v3 and v4 store base at different locations
    expect(router.history?.base ?? router.options.history?.base).toBe(base);
  });
});
