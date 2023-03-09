import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import GeoSettingsApp from 'ee/geo_settings/components/app.vue';
import GeoSettingsForm from 'ee/geo_settings/components/geo_settings_form.vue';
import initStore from 'ee/geo_settings/store';
import * as types from 'ee/geo_settings/store/mutation_types';

Vue.use(Vuex);

describe('GeoSettingsApp', () => {
  let wrapper;
  let store;

  const createStore = () => {
    store = initStore();
    jest.spyOn(store, 'dispatch').mockImplementation();
  };

  const createComponent = () => {
    wrapper = shallowMount(GeoSettingsApp, {
      store,
    });
  };

  const findGeoSettingsContainer = () => wrapper.find('[data-testid="geoSettingsContainer"]');
  const containsGeoSettingsForm = () => wrapper.findComponent(GeoSettingsForm).exists();
  const containsGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon).exists();

  describe('renders', () => {
    beforeEach(() => {
      createStore();
      createComponent();
    });

    it('the settings container', () => {
      expect(findGeoSettingsContainer().exists()).toBe(true);
    });

    it('header text', () => {
      expect(findGeoSettingsContainer().text()).toContain(GeoSettingsApp.i18n.geoSettingsTitle);
    });

    describe('when not loading', () => {
      it('Geo Settings Form', () => {
        expect(containsGeoSettingsForm()).toBe(true);
      });

      it('not GlLoadingIcon', () => {
        expect(containsGlLoadingIcon()).toBe(false);
      });
    });

    describe('when loading', () => {
      beforeEach(() => {
        store.commit(types.REQUEST_GEO_SETTINGS);
      });

      it('not Geo Settings Form', () => {
        expect(containsGeoSettingsForm()).toBe(false);
      });

      it('GlLoadingIcon', () => {
        expect(containsGlLoadingIcon()).toBe(true);
      });
    });
  });

  describe('onCreate', () => {
    beforeEach(() => {
      createStore();
      createComponent();
    });

    it('calls fetchGeoSettings', () => {
      expect(store.dispatch).toHaveBeenCalledWith('fetchGeoSettings');
    });
  });
});
