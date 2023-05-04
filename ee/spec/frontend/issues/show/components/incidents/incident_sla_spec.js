import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import IncidentSla from 'ee/issues/show/components/incidents/incident_sla.vue';
import ServiceLevelAgreement from 'ee_component/vue_shared/components/incidents/service_level_agreement.vue';

jest.mock('~/lib/utils/datetime_utility');

const defaultProvide = { fullPath: 'test', iid: '1', slaFeatureAvailable: true };
const mockSlaDueAt = '2020-01-01T00:00:00.000Z';

describe('Incident SLA', () => {
  let wrapper;

  const mountComponent = (options) => {
    wrapper = shallowMount(
      IncidentSla,
      merge(
        {
          data() {
            return { slaDueAt: mockSlaDueAt, hasData: true };
          },
          provide: { ...defaultProvide },
        },
        options,
      ),
    );
  };

  const findSLA = () => wrapper.findComponent(ServiceLevelAgreement);

  it('renders a blank component when there is no data', () => {
    mountComponent({
      data() {
        return { hasData: false };
      },
    });

    expect(wrapper.isVisible()).toBe(false);
  });

  it('renders a blank component when feature is not available', () => {
    mountComponent({
      provide: {
        ...defaultProvide,
        slaFeatureAvailable: false,
      },
    });

    expect(wrapper.isVisible()).toBe(false);
  });

  it('renders an incident SLA when sla is present and feature is available', () => {
    mountComponent();

    expect(wrapper.isVisible()).toBe(true);
    expect(findSLA().attributes('sladueat')).toBe(mockSlaDueAt);
  });
});
