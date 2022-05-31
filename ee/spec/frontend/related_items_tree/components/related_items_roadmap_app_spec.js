import Vue from 'vue';
import Vuex from 'vuex';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createDefaultStore from 'ee/related_items_tree/store';
import RelatedItemsRoadmapApp from 'ee/related_items_tree/components/related_items_roadmap_app.vue';

import { mockInitialConfig, mockRoadmapAppData } from '../mock_data';

Vue.use(Vuex);

const createComponent = ({ initialConfig = {} } = {}) => {
  const store = createDefaultStore();

  store.dispatch('setInitialConfig', { ...mockInitialConfig, ...initialConfig });

  return shallowMountExtended(RelatedItemsRoadmapApp, {
    store,
    provide: {
      roadmapAppData: mockRoadmapAppData,
    },
  });
};

describe('RelatedItemsTree', () => {
  describe('RelatedItemsRoadmapApp', () => {
    // https://gitlab.com/gitlab-org/gitlab/-/issues/363214
    // eslint-disable-next-line jest/no-disabled-tests
    describe.skip('template', () => {
      let wrapper = null;
      beforeEach(() => {
        wrapper = createComponent();
      });
      afterEach(() => {
        wrapper.destroy();
      });

      it('renders html', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('renders data-* attrs', () => {
        const el = wrapper.find('#js-roadmap');

        const normalizedData = Object.keys(mockRoadmapAppData).reduce((acc, key) => {
          const hypenCasedKey = key.replace(/_/g, '-');
          acc[`data-${hypenCasedKey}`] = mockRoadmapAppData[key];
          return acc;
        }, {});

        Object.keys(normalizedData).forEach((key) => {
          expect(el.attributes()[key]).toBe(normalizedData[key]);
        });
      });
    });

    describe('initRoadmap', () => {
      let wrapper = null;
      let initRoadmap = null;
      beforeEach(() => {
        initRoadmap = jest
          .spyOn(RelatedItemsRoadmapApp.methods, 'initRoadmap')
          .mockReturnValue(Promise.resolve());
      });
      afterEach(() => {
        wrapper.destroy();
      });

      it('does not load roadmap', () => {
        wrapper = createComponent({
          initialConfig: {
            allowSubEpics: false,
          },
        });
        expect(initRoadmap).not.toHaveBeenCalled();
      });

      it('loads roadmap', () => {
        wrapper = createComponent({});
        expect(initRoadmap).toHaveBeenCalled();
      });
    });
  });
});
