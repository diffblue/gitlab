import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GeoNodeHealthStatus from 'ee/geo_nodes/components/header/geo_node_health_status.vue';
import { HEALTH_STATUS_UI } from 'ee/geo_nodes/constants';

describe('GeoNodeHealthStatus', () => {
  let wrapper;

  const defaultProps = {
    status: 'Healthy',
  };

  const createComponent = (props) => {
    wrapper = shallowMount(GeoNodeHealthStatus, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoStatusBadge = () => wrapper.findComponent(GlBadge);

  describe.each`
    status         | uiData
    ${undefined}   | ${HEALTH_STATUS_UI.unknown}
    ${'Healthy'}   | ${HEALTH_STATUS_UI.healthy}
    ${'Unhealthy'} | ${HEALTH_STATUS_UI.unhealthy}
    ${'Disabled'}  | ${HEALTH_STATUS_UI.disabled}
    ${'Unknown'}   | ${HEALTH_STATUS_UI.unknown}
    ${'Offline'}   | ${HEALTH_STATUS_UI.offline}
  `(`template`, ({ status, uiData }) => {
    beforeEach(() => {
      createComponent({ status });
    });

    describe(`when status is ${status}`, () => {
      it(`renders badge variant to ${uiData.variant}`, () => {
        expect(findGeoStatusBadge().attributes('variant')).toBe(uiData.variant);
      });

      it(`renders icon to ${uiData.icon}`, () => {
        expect(findGeoStatusBadge().props('icon')).toBe(uiData.icon);
      });

      it(`renders status text to ${uiData.text}`, () => {
        expect(findGeoStatusBadge().text()).toBe(uiData.text);
      });
    });
  });
});
