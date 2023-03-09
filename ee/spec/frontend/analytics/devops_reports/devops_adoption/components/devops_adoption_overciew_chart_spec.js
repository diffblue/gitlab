import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import DevopsAdoptionOverviewChart from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_overview_chart.vue';
import getSnapshotsQuery from 'ee/analytics/devops_reports/devops_adoption/graphql/queries/devops_adoption_overview_chart.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { namespaceWithSnapotsData } from '../mock_data';

Vue.use(VueApollo);

const mockWithData = jest.fn().mockResolvedValue(namespaceWithSnapotsData);

describe('DevopsAdoptionOverviewChart', () => {
  let wrapper;

  const createComponent = ({ stubs = {}, mockSnapshotsQuery = mockWithData, data = {} } = {}) => {
    const handlers = [[getSnapshotsQuery, mockSnapshotsQuery]];

    wrapper = shallowMount(DevopsAdoptionOverviewChart, {
      provide: {
        groupGid:
          namespaceWithSnapotsData.data.devopsAdoptionEnabledNamespaces.nodes[0].namespace.id,
      },
      apolloProvider: createMockApollo(handlers),
      data() {
        return {
          ...data,
        };
      },
      stubs,
    });
  };

  describe('default state', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('does not display the chart loader', () => {
      expect(wrapper.findComponent(ChartSkeletonLoader).exists()).toBe(false);
    });

    it('displays the chart', () => {
      expect(wrapper.findComponent(GlStackedColumnChart).exists()).toBe(true);
    });

    it('computes the correct series data', () => {
      expect(wrapper.findComponent(GlStackedColumnChart).props('bars')).toMatchSnapshot();
    });
  });

  describe('loading', () => {
    it('displays the chart loader', () => {
      createComponent({});
      expect(wrapper.findComponent(ChartSkeletonLoader).exists()).toBe(true);
    });

    it('does not display the chart', () => {
      createComponent({});
      expect(wrapper.findComponent(GlStackedColumnChart).exists()).toBe(false);
    });
  });

  describe('chart tooltip', () => {
    beforeEach(async () => {
      const mockParams = {
        value: 'Jan',
        seriesData: [{ dataIndex: 0 }],
      };

      createComponent({
        stubs: {
          GlStackedColumnChart: {
            props: ['formatTooltipText'],
            mounted() {
              this.formatTooltipText(mockParams);
            },
            template: `
                <div>
                  <slot name="tooltip-title"></slot>
                  <slot name="tooltip-content"></slot>
                </div>`,
          },
        },
        data: {
          devopsAdoptionEnabledNamespaces: {
            nodes: namespaceWithSnapotsData.data.devopsAdoptionEnabledNamespaces.nodes,
          },
        },
      });
      await waitForPromises();
    });

    it('displays the tooltip information correctly', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
