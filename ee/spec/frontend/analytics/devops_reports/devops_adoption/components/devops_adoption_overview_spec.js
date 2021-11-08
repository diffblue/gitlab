import { GlLoadingIcon } from '@gitlab/ui';
import DevopsAdoptionOverviewChart from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_overview_chart.vue';
import DevopsAdoptionOverview from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_overview.vue';
import DevopsAdoptionOverviewCard from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_overview_card.vue';
import DevopsAdoptionOverviewTable from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_overview_table.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { devopsAdoptionNamespaceData, overallAdoptionData } from '../mock_data';

describe('DevopsAdoptionOverview', () => {
  let wrapper;

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(DevopsAdoptionOverview, {
      propsData: {
        timestamp: '2020-10-31 23:59',
        data: devopsAdoptionNamespaceData,
        ...props,
      },
      provide,
    });
  };

  describe('default state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the overview container', () => {
      expect(wrapper.findByTestId('overview-container').exists()).toBe(true);
    });

    describe('overview container', () => {
      it('displays the header text', () => {
        const text = wrapper.findByTestId('overview-container-header');

        expect(text.exists()).toBe(true);
        expect(text.text()).toBe(
          'Feature adoption is based on usage in the previous calendar month. Data is updated at the beginning of each month. Last updated: 2020-10-31 23:59.',
        );
      });

      it('displays the correct numnber of overview cards', () => {
        expect(wrapper.findAllComponents(DevopsAdoptionOverviewCard)).toHaveLength(4);
      });

      it('passes the cards the correct data', () => {
        expect(wrapper.findComponent(DevopsAdoptionOverviewCard).props()).toStrictEqual(
          overallAdoptionData,
        );
      });

      it('displays the overview table', () => {
        expect(wrapper.findComponent(DevopsAdoptionOverviewTable).exists()).toBe(true);
      });

      it('does not display the overview chart', () => {
        expect(wrapper.findComponent(DevopsAdoptionOverviewChart).exists()).toBe(false);
      });
    });
  });

  describe('loading', () => {
    beforeEach(() => {
      createComponent({ props: { loading: true } });
    });

    it('displays a loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not display the overview container', () => {
      expect(wrapper.findByTestId('overview-container').exists()).toBe(false);
    });
  });

  describe('group level', () => {
    beforeEach(() => {
      createComponent({ provide: { groupGid: 'gid:123' } });
    });

    it('displays the overview chart', () => {
      expect(wrapper.findComponent(DevopsAdoptionOverviewChart).exists()).toBe(true);
    });
  });
});
