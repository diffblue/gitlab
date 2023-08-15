import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createDefaultStore from 'ee/related_items_tree/store';
import RelatedItemsRoadmapApp from 'ee/related_items_tree/components/related_items_roadmap_app.vue';

import { mockTracking } from 'helpers/tracking_helper';
import {
  ROADMAP_ACTIVITY_TRACK_ACTION_LABEL,
  ROADMAP_ACTIVITY_TRACK_LABEL,
} from 'ee/related_items_tree/constants';
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
    // quarantine: https://gitlab.com/gitlab-org/gitlab/-/issues/363214
    // eslint-disable-next-line jest/no-disabled-tests
    describe.skip('template', () => {
      let wrapper = null;
      beforeEach(() => {
        wrapper = createComponent();
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
      let initRoadmap = null;
      beforeEach(() => {
        initRoadmap = jest
          .spyOn(RelatedItemsRoadmapApp.methods, 'initRoadmap')
          .mockReturnValue(Promise.resolve());
      });

      it('does not load roadmap', () => {
        createComponent({
          initialConfig: {
            allowSubEpics: false,
          },
        });
        expect(initRoadmap).not.toHaveBeenCalled();
      });

      it('loads roadmap', () => {
        createComponent({});
        expect(initRoadmap).toHaveBeenCalled();
      });
    });

    // quarantine: https://gitlab.com/gitlab-org/gitlab/-/issues/407474
    // eslint-disable-next-line jest/no-disabled-tests
    describe.skip('roadmap tab', () => {
      it('tracks loading of the component', async () => {
        const wrapper = createComponent();
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        await waitForPromises();

        expect(trackingSpy).toHaveBeenCalledWith(undefined, ROADMAP_ACTIVITY_TRACK_ACTION_LABEL, {
          label: ROADMAP_ACTIVITY_TRACK_LABEL,
        });
      });
    });
  });
});
