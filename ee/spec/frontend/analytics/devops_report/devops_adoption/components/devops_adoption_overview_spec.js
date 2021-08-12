import { GlLoadingIcon } from '@gitlab/ui';
import DevopsAdoptionOverview from 'ee/analytics/devops_report/devops_adoption/components/devops_adoption_overview.vue';
import DevopsAdoptionOverviewCard from 'ee/analytics/devops_report/devops_adoption/components/devops_adoption_overview_card.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { devopsAdoptionNamespaceData, overallAdoptionData } from '../mock_data';

describe('DevopsAdoptionOverview', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMountExtended(DevopsAdoptionOverview, {
      propsData: {
        timestamp: '2020-10-31 23:59',
        data: devopsAdoptionNamespaceData,
        ...props,
      },
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
    });
  });

  describe('loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('displays a loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not display the overview container', () => {
      expect(wrapper.findByTestId('overview-container').exists()).toBe(false);
    });
  });
});
