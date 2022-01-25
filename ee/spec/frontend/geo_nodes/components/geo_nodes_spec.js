import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import GeoNodeDetails from 'ee/geo_nodes/components/details/geo_node_details.vue';
import GeoNodes from 'ee/geo_nodes/components/geo_nodes.vue';
import GeoNodeHeader from 'ee/geo_nodes/components/header/geo_node_header.vue';
import { MOCK_NODES } from '../mock_data';

describe('GeoNodes', () => {
  let wrapper;

  const defaultProps = {
    node: MOCK_NODES[0],
  };

  const createComponent = (props) => {
    wrapper = shallowMount(GeoNodes, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodesContainer = () => wrapper.find('div');
  const findGeoNodeHeader = () => wrapper.findComponent(GeoNodeHeader);
  const findGeoNodeDetails = () => wrapper.findComponent(GeoNodeDetails);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the Geo Nodes Container always', () => {
      expect(findGeoNodesContainer().exists()).toBe(true);
    });

    it('renders the Geo Node Header always', () => {
      expect(findGeoNodeHeader().exists()).toBe(true);
    });

    describe('Node Details', () => {
      it('renders by default', () => {
        expect(findGeoNodeDetails().exists()).toBe(true);
      });

      it('is hidden when toggled', async () => {
        findGeoNodeHeader().vm.$emit('collapse');

        await nextTick();
        expect(findGeoNodeDetails().exists()).toBe(false);
      });
    });
  });
});
