import { GlLoadingIcon } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import SecurityTrainingPromoBanner from 'ee/security_dashboard/components/project/security_training_promo_banner.vue';
import ProjectSecurityDashboard from 'ee/security_dashboard/components/project/project_security_dashboard.vue';
import projectsHistoryQuery from 'ee/security_dashboard/graphql/queries/project_vulnerabilities_by_day_and_count.query.graphql';
import { useFakeDate } from 'helpers/fake_date';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockProjectSecurityChartsWithData } from '../../mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/icon_utils', () => ({
  getSvgIconPathContent: jest.fn().mockResolvedValue('mockSvgPathContent'),
}));

describe('Project Security Dashboard component', () => {
  let wrapper;

  const projectFullPath = 'project/path';

  const findLineChart = () => wrapper.findComponent(GlLineChart);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findSecurityTrainingPromoBanner = () => wrapper.findComponent(SecurityTrainingPromoBanner);

  const createApolloProvider = (...queries) => {
    return createMockApollo([...queries]);
  };

  const createWrapper = ({ queryData } = {}) => {
    wrapper = shallowMount(ProjectSecurityDashboard, {
      apolloProvider: createApolloProvider([
        projectsHistoryQuery,
        jest.fn().mockResolvedValue(queryData),
      ]),
      propsData: { projectFullPath },
    });
  };

  describe('when query is loading', () => {
    it('should only show the loading icon', () => {
      createWrapper();

      expect(findLineChart().exists()).toBe(false);
      expect(findSecurityTrainingPromoBanner().exists()).toBe(false);
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when there is history data', () => {
    useFakeDate(2021, 3, 11);

    beforeEach(() => {
      createWrapper({ queryData: mockProjectSecurityChartsWithData() });
      return nextTick();
    });

    it('should display the chart with data', () => {
      expect(findLineChart().props('data')).toMatchSnapshot();
    });

    it('should display the chart with responsive attribute', () => {
      expect(findLineChart().attributes('responsive')).toBeDefined();
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
      expect(findSecurityTrainingPromoBanner().exists()).toBe(true);
    });
  });
});
