import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GeoNodeActions from 'ee/geo_nodes/components/header/geo_node_actions.vue';
import GeoNodeHeader from 'ee/geo_nodes/components/header/geo_node_header.vue';
import GeoNodeHealthStatus from 'ee/geo_nodes/components/header/geo_node_health_status.vue';
import GeoNodeLastUpdated from 'ee/geo_nodes/components/header/geo_node_last_updated.vue';
import { MOCK_PRIMARY_NODE, MOCK_SECONDARY_NODE } from 'ee_jest/geo_nodes/mock_data';

describe('GeoNodeHeader', () => {
  let wrapper;

  const defaultProps = {
    node: MOCK_PRIMARY_NODE,
    collapsed: false,
  };

  const createComponent = (props) => {
    wrapper = shallowMount(GeoNodeHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findHeaderCollapseButton = () => wrapper.findComponent(GlButton);
  const findGeoNodeHealthStatus = () => wrapper.findComponent(GeoNodeHealthStatus);
  const findGeoNodeLastUpdated = () => wrapper.findComponent(GeoNodeLastUpdated);
  const findGeoNodeActions = () => wrapper.findComponent(GeoNodeActions);

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the Geo Node Health Status', () => {
        expect(findGeoNodeHealthStatus().exists()).toBe(true);
      });

      it('renders the Geo Node Actions', () => {
        expect(findGeoNodeActions().exists()).toBe(true);
      });
    });

    describe('Header Collapse Icon', () => {
      describe('when not collapsed', () => {
        beforeEach(() => {
          createComponent();
        });

        it('renders the chevron-down icon', () => {
          expect(findHeaderCollapseButton().attributes('icon')).toBe('chevron-down');
        });
      });

      describe('when collapsed', () => {
        beforeEach(() => {
          createComponent({ collapsed: true });
        });

        it('renders the chevron-right icon', () => {
          expect(findHeaderCollapseButton().attributes('icon')).toBe('chevron-right');
        });
      });

      describe('on click', () => {
        beforeEach(() => {
          createComponent();

          findHeaderCollapseButton().vm.$emit('click');
        });

        it('emits the collapse event', () => {
          expect(wrapper.emitted('collapse')).toHaveLength(1);
        });
      });
    });

    describe('Last updated', () => {
      describe('when lastSuccessfulStatusCheckTimestamp exists', () => {
        beforeEach(() => {
          createComponent({
            node: {
              ...MOCK_SECONDARY_NODE,
              lastSuccessfulStatusCheckTimestamp: new Date().getTime(),
            },
          });
        });

        it('renders', () => {
          expect(findGeoNodeLastUpdated().exists()).toBe(true);
        });
      });

      describe('when lastSuccessfulStatusCheckTimestamp does not exist', () => {
        beforeEach(() => {
          createComponent();
        });

        it('renders', () => {
          expect(findGeoNodeLastUpdated().exists()).toBe(false);
        });
      });
    });
  });
});
