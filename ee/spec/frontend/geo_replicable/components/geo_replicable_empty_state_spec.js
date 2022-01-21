import { getByRole } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoReplicableEmptyState from 'ee/geo_replicable/components/geo_replicable_empty_state.vue';
import createStore from 'ee/geo_replicable/store';
import {
  MOCK_GEO_REPLICATION_SVG_PATH,
  MOCK_GEO_TROUBLESHOOTING_LINK,
  MOCK_REPLICABLE_TYPE,
} from '../mock_data';

Vue.use(Vuex);

describe('GeoReplicableEmptyState', () => {
  let wrapper;

  const propsData = {
    geoTroubleshootingLink: MOCK_GEO_TROUBLESHOOTING_LINK,
    geoReplicableEmptySvgPath: MOCK_GEO_REPLICATION_SVG_PATH,
  };

  const createComponent = () => {
    wrapper = mount(GeoReplicableEmptyState, {
      store: createStore({ replicableType: MOCK_REPLICABLE_TYPE, graphqlFieldName: null }),
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders correct link', () => {
      expect(
        getByRole(wrapper.element, 'link', { name: 'Geo Troubleshooting' }).getAttribute('href'),
      ).toBe(MOCK_GEO_TROUBLESHOOTING_LINK);
    });

    it('sets correct svg', () => {
      expect(getByRole(wrapper.element, 'img').getAttribute('src')).toBe(
        MOCK_GEO_REPLICATION_SVG_PATH,
      );
    });
  });
});
