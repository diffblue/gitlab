import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoReplicableEmptyState from 'ee/geo_replicable/components/geo_replicable_empty_state.vue';
import { GEO_TROUBLESHOOTING_LINK } from 'ee/geo_replicable/constants';
import { MOCK_GEO_REPLICATION_SVG_PATH, MOCK_REPLICABLE_TYPE } from '../mock_data';

Vue.use(Vuex);

describe('GeoReplicableEmptyState', () => {
  let wrapper;

  const propsData = {
    geoReplicableEmptySvgPath: MOCK_GEO_REPLICATION_SVG_PATH,
  };

  const createComponent = (getters) => {
    const store = new Vuex.Store({
      getters: {
        replicableTypeName: () => MOCK_REPLICABLE_TYPE,
        hasFilters: () => false,
        ...getters,
      },
    });

    wrapper = shallowMount(GeoReplicableEmptyState, {
      store,
      propsData,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findGlLink = () => wrapper.findComponent(GlLink);

  describe.each`
    hasFilters | title                                             | description                                 | link
    ${false}   | ${`There are no ${MOCK_REPLICABLE_TYPE} to show`} | ${`No ${MOCK_REPLICABLE_TYPE} were found.`} | ${GEO_TROUBLESHOOTING_LINK}
    ${true}    | ${'No results found'}                             | ${'Edit your search filter and try again.'} | ${false}
  `('template when hasFilters is $hasFilters', ({ hasFilters, title, description, link }) => {
    beforeEach(() => {
      createComponent({ hasFilters: () => hasFilters });
    });

    it(`sets empty state title to ${title}`, () => {
      expect(findGlEmptyState().props('title')).toBe(title);
    });

    it(`sets empty state description to ${description}`, () => {
      expect(findGlEmptyState().text()).toContain(description);
    });

    it(`does${link ? '' : ' not'} provide a help link to ${GEO_TROUBLESHOOTING_LINK}`, () => {
      expect(findGlLink().exists() && findGlLink().attributes('href')).toBe(link);
    });

    it(`sets empty state image to ${MOCK_GEO_REPLICATION_SVG_PATH}`, () => {
      expect(findGlEmptyState().props('svgPath')).toBe(MOCK_GEO_REPLICATION_SVG_PATH);
    });
  });
});
