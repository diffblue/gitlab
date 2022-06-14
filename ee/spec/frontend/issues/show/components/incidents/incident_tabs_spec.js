import { shallowMount } from '@vue/test-utils';
import merge from 'lodash/merge';
import IncidentTabs from '~/issues/show/components/incidents/incident_tabs.vue';
import INVALID_URL from '~/lib/utils/invalid_url';
import { descriptionProps } from 'jest/issues/show/mock_data/mock_data';

const mockAlert = {
  __typename: 'AlertManagementAlert',
  detailsUrl: INVALID_URL,
  iid: '1',
};

describe('Incident Tabs component', () => {
  let wrapper;

  const mountComponent = (data = {}, options = {}) => {
    wrapper = shallowMount(
      IncidentTabs,
      merge(
        {
          propsData: {
            ...descriptionProps,
          },
          stubs: {
            DescriptionComponent: true,
            MetricsTab: true,
          },
          provide: {
            fullPath: '',
            iid: '',
            projectId: '',
            issuableId: '',
            uploadMetricsFeatureAvailable: true,
          },
          data() {
            return { alert: mockAlert, ...data };
          },
          mocks: {
            $apollo: {
              queries: {
                alert: {
                  loading: true,
                },
              },
            },
          },
        },
        options,
      ),
    );
  };

  const findMetricsTab = () => wrapper.find('[data-testid="metrics-tab"]');

  describe('upload metrics feature available', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows the metric tab when metrics are available', () => {
      mountComponent({}, { provide: { uploadMetricsFeatureAvailable: true } });

      expect(findMetricsTab().exists()).toBe(true);
    });

    it('hides the tab when metrics are not available', () => {
      mountComponent({}, { provide: { uploadMetricsFeatureAvailable: false } });

      expect(findMetricsTab().exists()).toBe(false);
    });
  });
});
