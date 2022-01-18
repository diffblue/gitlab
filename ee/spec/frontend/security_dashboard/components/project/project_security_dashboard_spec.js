import { GlLoadingIcon } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import ProjectSecurityDashboard from 'ee/security_dashboard/components/project/project_security_dashboard.vue';
import ReportNotConfigured from 'ee/security_dashboard/components/shared/empty_states/report_not_configured_project.vue';
import SecurityDashboardLayout from 'ee/security_dashboard/components/shared/security_dashboard_layout.vue';
import SecurityTrainingPromo from 'ee/security_dashboard/components/shared/security_training_promo.vue';
import projectsHistoryQuery from 'ee/security_dashboard/graphql/queries/project_vulnerabilities_by_day_and_count.query.graphql';
import { useFakeDate } from 'helpers/fake_date';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  mockProjectSecurityChartsWithData,
  mockProjectSecurityChartsWithoutData,
} from '../../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

jest.mock('~/lib/utils/icon_utils', () => ({
  getSvgIconPathContent: jest.fn().mockResolvedValue('mockSvgPathContent'),
}));

describe('Project Security Dashboard component', () => {
  let wrapper;

  const projectFullPath = 'project/path';
  const helpPath = 'docs/security/dashboard';

  const findLineChart = () => wrapper.findComponent(GlLineChart);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(ReportNotConfigured);
  const findSecurityTrainingPromo = () => wrapper.findComponent(SecurityTrainingPromo);

  const createApolloProvider = (...queries) => {
    return createMockApollo([...queries]);
  };

  const createComponent = ({
    query,
    propsData,
    chartWidth = 1024,
    secureVulnerabilityTrainingEnabled = true,
  }) => {
    const component = shallowMount(ProjectSecurityDashboard, {
      localVue,
      apolloProvider: createApolloProvider([
        projectsHistoryQuery,
        jest.fn().mockResolvedValue(query),
      ]),
      propsData: {
        projectFullPath,
        helpPath,
        ...propsData,
      },
      provide: {
        // To be consumed by SecurityDashboardLayout
        sbomSurveySvgPath: '/',
        glFeatures: {
          secureVulnerabilityTraining: secureVulnerabilityTrainingEnabled,
        },
      },
      stubs: {
        SecurityDashboardLayout,
      },
    });

    // Need to setData after the component is mounted
    component.setData({ chartWidth });

    return component;
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('when chartWidth is 0', () => {
    beforeEach(() => {
      wrapper = createComponent({
        query: mockProjectSecurityChartsWithData(),
        propsData: { hasVulnerabilities: true },
        chartWidth: 0,
      });
      return wrapper.vm.$nextTick();
    });

    it('should not display the line chart', () => {
      expect(findLineChart().exists()).toBe(false);
    });

    it('should display a loading icon instead', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when there is history data', () => {
    useFakeDate(2021, 3, 11);

    beforeEach(() => {
      wrapper = createComponent({
        query: mockProjectSecurityChartsWithData(),
        propsData: { hasVulnerabilities: true },
      });
      return wrapper.vm.$nextTick();
    });

    it('should display the chart with data', () => {
      expect(findLineChart().props('data')).toMatchSnapshot();
    });

    it('should not display the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it.each([['restore'], ['saveAsImage']])('should contain %i icon', (icon) => {
      const option = findLineChart().props('option').toolbox.feature;
      expect(option[icon].icon).toBe('path://mockSvgPathContent');
    });

    it('contains dataZoom config', () => {
      const option = findLineChart().props('option').toolbox.feature;
      expect(option.dataZoom.icon.zoom).toBe('path://mockSvgPathContent');
      expect(option.dataZoom.icon.back).toBe('path://mockSvgPathContent');
    });

    it('contains the timeline slider', () => {
      const { dataZoom } = findLineChart().props('option');
      expect(dataZoom[0]).toMatchObject({
        type: 'slider',
        handleIcon: 'path://mockSvgPathContent',
        startValue: '2021-03-12',
      });
    });

    it('contains a promotion for the security training feature', () => {
      expect(findSecurityTrainingPromo().exists()).toBe(true);
    });
  });

  describe('when there is no history data', () => {
    beforeEach(() => {
      wrapper = createComponent({
        query: mockProjectSecurityChartsWithoutData(),
        propsData: { hasVulnerabilities: false },
      });
      return wrapper.vm.$nextTick();
    });

    it('should display the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('should not display the chart', () => {
      expect(findLineChart().exists()).toBe(false);
    });

    it('should not display the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when the query is loading', () => {
    beforeEach(() => {
      wrapper = createComponent({
        query: () => ({}),
        propsData: { hasVulnerabilities: true },
      });
    });

    it('should not display the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('should not display the chart', () => {
      expect(findLineChart().exists()).toBe(false);
    });

    it('should display the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('with the "secureVulnerabilityTraining" feature flag disabled', () => {
    it('does not contain a promotion for the security training feature', async () => {
      wrapper = createComponent({
        query: mockProjectSecurityChartsWithData(),
        propsData: { hasVulnerabilities: true },
        secureVulnerabilityTrainingEnabled: false,
      });

      await wrapper.vm.$nextTick();

      expect(findSecurityTrainingPromo().exists()).toBe(false);
    });
  });
});
