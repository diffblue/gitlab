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

  const propsData = {
    site: MOCK_SITE,
    selectiveSyncTypes: MOCK_SELECTIVE_SYNC_TYPES,
    syncShardsOptions: MOCK_SYNC_SHARDS,
  };

  const createComponent = () => {
    wrapper = shallowMount(GeoSiteForm, {
      store: initStore(MOCK_SITES_PATH),
      propsData,
    });
  };

  const findGeoSiteFormCoreField = () => wrapper.findComponent(GeoSiteFormCore);
  const findGeoSiteFormSelectiveSyncField = () => wrapper.findComponent(GeoSiteFormSelectiveSync);
  const findGeoSiteFormCapacitiesField = () => wrapper.findComponent(GeoSiteFormCapacities);
  const findGeoSiteSaveButton = () => wrapper.find('#site-save-button');
  const findGeoSiteCancelButton = () => wrapper.find('#site-cancel-button');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    describe.each`
      primarySite | showCore | showSelectiveSync | showCapacities
      ${true}     | ${true}  | ${false}          | ${true}
      ${false}    | ${true}  | ${true}           | ${true}
    `(`conditional fields`, ({ primarySite, showCore, showSelectiveSync, showCapacities }) => {
      beforeEach(() => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          siteData: { ...wrapper.vm.siteData, primary: primarySite },
        });
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
          wrapper.vm.$store.state.formErrors.name = 'Test Error';
        });

        it('disables button', () => {
          expect(findGeoSiteSaveButton().attributes('disabled')).toBeDefined();
        });
      });

      describe('with mo errors on form', () => {
        it('does not disable button', () => {
          expect(findGeoSiteSaveButton().attributes('disabled')).toBeUndefined();
        });
      });
    });
  });

  describe('methods', () => {
    describe('saveGeoSite', () => {
      beforeEach(() => {
        createComponent();
        wrapper.vm.saveGeoSite = jest.fn();
      });

      it('calls saveGeoSite when save is clicked', () => {
        findGeoSiteSaveButton().vm.$emit('click');
        expect(wrapper.vm.saveGeoSite).toHaveBeenCalledWith(MOCK_SITE);
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
        expect(wrapper.vm.siteData.selectiveSyncShards).toEqual([]);
        wrapper.vm.addSyncOption({ key: 'selectiveSyncShards', value: MOCK_SYNC_SHARDS[0].value });
        expect(wrapper.vm.siteData.selectiveSyncShards).toEqual([MOCK_SYNC_SHARDS[0].value]);
      });
    });

    describe('removeSyncOption', () => {
      beforeEach(() => {
        createComponent();
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          siteData: { ...wrapper.vm.siteData, selectiveSyncShards: [MOCK_SYNC_SHARDS[0].value] },
        });
      });

      it('should remove value from siteData', () => {
        expect(wrapper.vm.siteData.selectiveSyncShards).toEqual([MOCK_SYNC_SHARDS[0].value]);
        wrapper.vm.removeSyncOption({ key: 'selectiveSyncShards', index: 0 });
        expect(wrapper.vm.siteData.selectiveSyncShards).toEqual([]);
      });
    });
  });

  describe('created', () => {
    describe('when site prop exists', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets siteData to the correct site', () => {
        expect(wrapper.vm.siteData.id).toBe(wrapper.vm.site.id);
      });
    });

    describe('when site prop does not exist', () => {
      beforeEach(() => {
        propsData.site = null;
        createComponent();
      });

      it('sets siteData to the default site data', () => {
        expect(wrapper.vm.siteData).not.toBeNull();
        expect(wrapper.vm.siteData.id).not.toBe(MOCK_SITE.id);
      });
    });
  });
});
