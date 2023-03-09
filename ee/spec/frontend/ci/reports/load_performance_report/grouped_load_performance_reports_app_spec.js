import { mount } from '@vue/test-utils';
import GroupedLoadPerformanceReportsApp from 'ee/ci/reports/load_performance_report/grouped_load_performance_reports_app.vue';
import Api from '~/api';

jest.mock('~/api.js');

describe('Grouped load performance reports app', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = mount(GroupedLoadPerformanceReportsApp, {
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

  describe('service ping events', () => {
    it('tracks an event when the widget is expanded', () => {
      wrapper.find('[data-testid="report-section-expand-button"]').trigger('click');

      expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(wrapper.vm.$options.expandEvent);
    });
  });
});
