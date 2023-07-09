import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoSiteForm from 'ee/geo_site_form/components/geo_site_form.vue';
import GeoSiteFormCapacities from 'ee/geo_site_form/components/geo_site_form_capacities.vue';
import GeoSiteFormCore from 'ee/geo_site_form/components/geo_site_form_core.vue';
import GeoSiteFormSelectiveSync from 'ee/geo_site_form/components/geo_site_form_selective_sync.vue';
import initStore from 'ee/geo_site_form/store';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  MOCK_SITE,
  MOCK_SELECTIVE_SYNC_TYPES,
  MOCK_SYNC_SHARDS,
  MOCK_SITES_PATH,
} from '../mock_data';

Vue.use(Vuex);

jest.mock('~/helpers/help_page_helper');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('GeoSiteForm', () => {
  let wrapper;
  let store;

  const createStore = () => {
    store = initStore(MOCK_SITES_PATH);
    jest.spyOn(store, 'dispatch').mockImplementation();
  };

  const createComponent = (props = {}) => {
    createStore();
    wrapper = shallowMount(GeoSiteForm, {
      store,
      propsData: {
        site: MOCK_SITE,
        selectiveSyncTypes: MOCK_SELECTIVE_SYNC_TYPES,
        syncShardsOptions: MOCK_SYNC_SHARDS,
        ...props,
      },
    });
  };

  const findGeoSiteFormCoreField = () => wrapper.findComponent(GeoSiteFormCore);
  const findGeoSiteFormSelectiveSyncField = () => wrapper.findComponent(GeoSiteFormSelectiveSync);
  const findGeoSiteFormCapacitiesField = () => wrapper.findComponent(GeoSiteFormCapacities);
  const findGeoSiteSaveButton = () => wrapper.find('#site-save-button');
  const findGeoSiteCancelButton = () => wrapper.find('#site-cancel-button');

  describe('template', () => {
    describe.each`
      primarySite | showCore | showSelectiveSync | showCapacities
      ${true}     | ${true}  | ${false}          | ${true}
      ${false}    | ${true}  | ${true}           | ${true}
    `(`conditional fields`, ({ primarySite, showCore, showSelectiveSync, showCapacities }) => {
      beforeEach(() => {
        createComponent({ site: { MOCK_SITE, primary: primarySite } });
      });

      it(`it ${showCore ? 'shows' : 'hides'} the Core Field`, () => {
        expect(findGeoSiteFormCoreField().exists()).toBe(showCore);
      });

      it(`it ${showSelectiveSync ? 'shows' : 'hides'} the Selective Sync Field`, () => {
        expect(findGeoSiteFormSelectiveSyncField().exists()).toBe(showSelectiveSync);
      });

      it(`it ${showCapacities ? 'shows' : 'hides'} the Capacities Field`, () => {
        expect(findGeoSiteFormCapacitiesField().exists()).toBe(showCapacities);
      });
    });

    describe('Save Button', () => {
      describe('with errors on form', () => {
        beforeEach(() => {
          createComponent();
          store.state.formErrors.name = 'Test Error';
        });

        it('disables button', () => {
          expect(findGeoSiteSaveButton().attributes('disabled')).toBeDefined();
        });
      });

      describe('with mo errors on form', () => {
        it('does not disable button', () => {
          createComponent();

          expect(findGeoSiteSaveButton().attributes('disabled')).toBeUndefined();
        });
      });
    });
  });

  describe('methods', () => {
    describe('saveGeoSite', () => {
      beforeEach(() => {
        createComponent();
      });

      it('calls saveGeoSite when save is clicked', () => {
        findGeoSiteSaveButton().vm.$emit('click');
        expect(store.dispatch).toHaveBeenCalledWith('saveGeoSite', MOCK_SITE);
      });
    });

    describe('redirect', () => {
      beforeEach(() => {
        createComponent();
      });

      it('calls visitUrl when cancel is clicked', () => {
        findGeoSiteCancelButton().vm.$emit('click');
        expect(visitUrl).toHaveBeenCalledWith(MOCK_SITES_PATH);
      });
    });

    describe('addSyncOption', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should add value to siteData', () => {
        expect(findGeoSiteFormSelectiveSyncField().props('siteData').selectiveSyncShards).toEqual(
          [],
        );

        findGeoSiteFormSelectiveSyncField().vm.$emit('addSyncOption', {
          key: 'selectiveSyncShards',
          value: MOCK_SYNC_SHARDS[0].value,
        });

        expect(findGeoSiteFormSelectiveSyncField().props('siteData').selectiveSyncShards).toEqual([
          MOCK_SYNC_SHARDS[0].value,
        ]);
      });
    });

    describe('removeSyncOption', () => {
      beforeEach(() => {
        createComponent({ site: { selectiveSyncShards: [MOCK_SYNC_SHARDS[0].value] } });
      });

      it('should remove value from siteData', () => {
        expect(findGeoSiteFormSelectiveSyncField().props('siteData').selectiveSyncShards).toEqual([
          MOCK_SYNC_SHARDS[0].value,
        ]);
        findGeoSiteFormSelectiveSyncField().vm.$emit('removeSyncOption', {
          key: 'selectiveSyncShards',
          index: 0,
        });

        expect(findGeoSiteFormSelectiveSyncField().props('siteData').selectiveSyncShards).toEqual(
          [],
        );
      });
    });
  });

  describe('created', () => {
    describe('when site prop exists', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets siteData to the correct site', () => {
        expect(findGeoSiteFormCoreField().props('siteData').id).toBe(MOCK_SITE.id);
        expect(findGeoSiteFormSelectiveSyncField().props('siteData').id).toBe(MOCK_SITE.id);
        expect(findGeoSiteFormCapacitiesField().props('siteData').id).toBe(MOCK_SITE.id);
      });
    });

    describe('when site prop does not exist', () => {
      beforeEach(() => {
        createComponent({ site: null });
      });

      it('sets siteData to the default site data', () => {
        expect(findGeoSiteFormCoreField().props('siteData').id).not.toBe(MOCK_SITE.id);
        expect(findGeoSiteFormSelectiveSyncField().props('siteData').id).not.toBe(MOCK_SITE.id);
        expect(findGeoSiteFormCapacitiesField().props('siteData').id).not.toBe(MOCK_SITE.id);
      });
    });
  });
});
