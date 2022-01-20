import { mount } from '@vue/test-utils';
import EnvironmentAlert from 'ee/environments/components/environment_alert.vue';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';

describe('Environment Alert', () => {
  let wrapper;
  const DEFAULT_PROVIDE = { projectPath: 'test-org/test' };
  const DEFAULT_PROPS = { environment: { name: 'staging' } };

  const factory = (props = {}, provide = {}) => {
    wrapper = mount(EnvironmentAlert, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
      provide: {
        ...DEFAULT_PROVIDE,
        ...provide,
      },
    });
  };

  const findSeverityBadge = () => wrapper.findComponent(SeverityBadge);

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('has alert', () => {
    beforeEach(() => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        alert: {
          severity: 'CRITICAL',
          title: 'alert title',
          prometheusAlert: { humanizedText: '>0.1% jest' },
          detailsUrl: '/alert/details',
          startedAt: new Date(),
        },
      });
    });

    it('should display the alert details', () => {
      const text = wrapper.text();
      expect(text).toContain('Critical');
      expect(text).toContain('alert title >0.1% jest.');
      expect(text).toContain('View Details');
      expect(text).toContain('just now');
    });

    it('should link to the details of the alert', () => {
      const link = wrapper.find('[data-testid="alert-link"]');
      expect(link.text()).toBe('View Details');
      expect(link.attributes('href')).toBe('/alert/details');
    });

    it('should show a severity badge with the correct severity', () => {
      const badge = findSeverityBadge();
      expect(badge.exists()).toBe(true);
      expect(badge.props('severity')).toBe('CRITICAL');
    });
  });

  describe('has no alert', () => {
    it('should display nothing', () => {
      expect(wrapper.find('[data-testid="alert"]').exists()).toBe(false);
      expect(findSeverityBadge().exists()).toBe(false);
    });
  });
});
