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
            uploadMetricsFeatureAvailable: true,
            glFeatures: { incidentTimelineEventTab: true, incidentTimelineEvents: true },
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

  const findTimelineTab = () => wrapper.find('[data-testid="timeline-events-tab"]');

  describe('incident timeline tab', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders the timeline tab when feature flag is enabled', () => {
      expect(findTimelineTab().exists()).toBe(true);
      expect(findTimelineTab().attributes('title')).toBe('Timeline');
    });

    it('does not render timeline tab when feature flag is disabled', () => {
      mountComponent({}, { provide: { glFeatures: { incidentTimelineEventTab: false } } });

      expect(findTimelineTab().exists()).toBe(false);
    });

    it('does not render timeline tab when not available in license', () => {
      mountComponent({}, { provide: { glFeatures: { incidentTimelineEvents: false } } });

      expect(findTimelineTab().exists()).toBe(false);
    });
  });
});
