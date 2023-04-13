import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import EnvironmentAlert from 'ee/environments/components/environment_alert.vue';
import alertQuery from 'ee/environments/graphql/queries/environment.query.graphql';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import createMockApollo from 'helpers/mock_apollo_helper';

Vue.use(VueApollo);

describe('Environment Alert', () => {
  let wrapper;
  let alertResolver;
  const DEFAULT_PROVIDE = { projectPath: 'test-org/test' };
  const DEFAULT_PROPS = { environment: { name: 'staging' } };

  const createApolloProvider = () => createMockApollo([[alertQuery, alertResolver]]);

  const factory = (props = {}, provide = {}) => {
    const apolloProvider = createApolloProvider();

    wrapper = mount(EnvironmentAlert, {
      apolloProvider,
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
    alertResolver = jest.fn();
  });

  describe('has alert', () => {
    beforeEach(async () => {
      alertResolver.mockResolvedValue({
        data: {
          project: {
            id: '1',
            environment: {
              id: '2',
              latestOpenedMostSevereAlert: {
                id: '4',
                severity: 'CRITICAL',
                title: 'alert title',
                prometheusAlert: { id: '3', humanizedText: '>0.1% jest' },
                detailsUrl: '/alert/details',
                startedAt: new Date(),
              },
            },
          },
        },
      });

      await factory();
    });

    it('displays the alert details', () => {
      const text = wrapper.text();
      expect(text).toContain('Critical');
      expect(text).toContain('alert title >0.1% jest.');
      expect(text).toContain('View Details');
      expect(text).toContain('just now');
    });

    it('links to the details of the alert', () => {
      const link = wrapper.find('[data-testid="alert-link"]');
      expect(link.text()).toBe('View Details');
      expect(link.attributes('href')).toBe('/alert/details');
    });

    it('shows a severity badge with the correct severity', () => {
      const badge = findSeverityBadge();
      expect(badge.exists()).toBe(true);
      expect(badge.props('severity')).toBe('CRITICAL');
    });
  });

  describe('has no alert', () => {
    beforeEach(async () => {
      alertResolver.mockResolvedValue({
        data: {
          project: {
            id: '1',
            environment: {
              id: '2',
              latestOpenedMostSevereAlert: null,
            },
          },
        },
      });
      await factory();
    });

    it('displays nothing', () => {
      expect(wrapper.find('[data-testid="alert"]').exists()).toBe(false);
      expect(findSeverityBadge().exists()).toBe(false);
    });
  });
});
