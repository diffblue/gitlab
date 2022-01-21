import { mount } from '@vue/test-utils';
import GroupedBrowserPerformanceReportsApp from 'ee/reports/browser_performance_report/grouped_browser_performance_reports_app.vue';
import Api from '~/api';

jest.mock('~/api.js');

describe('Grouped test reports app', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = mount(GroupedBrowserPerformanceReportsApp, {
      propsData: {
        status: '',
        loadingText: '',
        errorText: '',
        successText: '',
        unresolvedIssues: [{}, {}],
        resolvedIssues: [],
        neutralIssues: [],
        hasIssues: true,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('service ping events', () => {
    it('tracks an event when the widget is expanded', () => {
      wrapper.find('[data-testid="report-section-expand-button"]').trigger('click');

      expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(wrapper.vm.$options.expandEvent);
    });
  });
});
