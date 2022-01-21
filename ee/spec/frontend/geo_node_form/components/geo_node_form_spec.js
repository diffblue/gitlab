import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoNodeForm from 'ee/geo_node_form/components/geo_node_form.vue';
import GeoNodeFormCapacities from 'ee/geo_node_form/components/geo_node_form_capacities.vue';
import GeoNodeFormCore from 'ee/geo_node_form/components/geo_node_form_core.vue';
import GeoNodeFormSelectiveSync from 'ee/geo_node_form/components/geo_node_form_selective_sync.vue';
import initStore from 'ee/geo_node_form/store';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  MOCK_NODE,
  MOCK_SELECTIVE_SYNC_TYPES,
  MOCK_SYNC_SHARDS,
  MOCK_NODES_PATH,
} from '../mock_data';

Vue.use(Vuex);

jest.mock('~/helpers/help_page_helper');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('GeoNodeForm', () => {
  let wrapper;

  const propsData = {
    node: MOCK_NODE,
    selectiveSyncTypes: MOCK_SELECTIVE_SYNC_TYPES,
    syncShardsOptions: MOCK_SYNC_SHARDS,
  };

  const createComponent = () => {
    wrapper = shallowMount(GeoNodeForm, {
      store: initStore(MOCK_NODES_PATH),
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodeFormCoreField = () => wrapper.findComponent(GeoNodeFormCore);
  const findGeoNodeFormSelectiveSyncField = () => wrapper.findComponent(GeoNodeFormSelectiveSync);
  const findGeoNodeFormCapacitiesField = () => wrapper.findComponent(GeoNodeFormCapacities);
  const findGeoNodeSaveButton = () => wrapper.find('#node-save-button');
  const findGeoNodeCancelButton = () => wrapper.find('#node-cancel-button');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    describe.each`
      primaryNode | showCore | showSelectiveSync | showCapacities
      ${true}     | ${true}  | ${false}          | ${true}
      ${false}    | ${true}  | ${true}           | ${true}
    `(`conditional fields`, ({ primaryNode, showCore, showSelectiveSync, showCapacities }) => {
      beforeEach(() => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          nodeData: { ...wrapper.vm.nodeData, primary: primaryNode },
        });
      });

      it(`it ${showCore ? 'shows' : 'hides'} the Core Field`, () => {
        expect(findGeoNodeFormCoreField().exists()).toBe(showCore);
      });

      it(`it ${showSelectiveSync ? 'shows' : 'hides'} the Selective Sync Field`, () => {
        expect(findGeoNodeFormSelectiveSyncField().exists()).toBe(showSelectiveSync);
      });

      it(`it ${showCapacities ? 'shows' : 'hides'} the Capacities Field`, () => {
        expect(findGeoNodeFormCapacitiesField().exists()).toBe(showCapacities);
      });
    });

    describe('Save Button', () => {
      describe('with errors on form', () => {
        beforeEach(() => {
          wrapper.vm.$store.state.formErrors.name = 'Test Error';
        });

        it('disables button', () => {
          expect(findGeoNodeSaveButton().attributes('disabled')).toBeTruthy();
        });
      });

      describe('with mo errors on form', () => {
        it('does not disable button', () => {
          expect(findGeoNodeSaveButton().attributes('disabled')).toBeFalsy();
        });
      });
    });
  });

  describe('methods', () => {
    describe('saveGeoNode', () => {
      beforeEach(() => {
        createComponent();
        wrapper.vm.saveGeoNode = jest.fn();
      });

      it('calls saveGeoNode when save is clicked', () => {
        findGeoNodeSaveButton().vm.$emit('click');
        expect(wrapper.vm.saveGeoNode).toHaveBeenCalledWith(MOCK_NODE);
      });
    });

    describe('redirect', () => {
      beforeEach(() => {
        createComponent();
      });

      it('calls visitUrl when cancel is clicked', () => {
        findGeoNodeCancelButton().vm.$emit('click');
        expect(visitUrl).toHaveBeenCalledWith(MOCK_NODES_PATH);
      });
    });

    describe('addSyncOption', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should add value to nodeData', () => {
        expect(wrapper.vm.nodeData.selectiveSyncShards).toEqual([]);
        wrapper.vm.addSyncOption({ key: 'selectiveSyncShards', value: MOCK_SYNC_SHARDS[0].value });
        expect(wrapper.vm.nodeData.selectiveSyncShards).toEqual([MOCK_SYNC_SHARDS[0].value]);
      });
    });

    describe('removeSyncOption', () => {
      beforeEach(() => {
        createComponent();
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          nodeData: { ...wrapper.vm.nodeData, selectiveSyncShards: [MOCK_SYNC_SHARDS[0].value] },
        });
      });

      it('should remove value from nodeData', () => {
        expect(wrapper.vm.nodeData.selectiveSyncShards).toEqual([MOCK_SYNC_SHARDS[0].value]);
        wrapper.vm.removeSyncOption({ key: 'selectiveSyncShards', index: 0 });
        expect(wrapper.vm.nodeData.selectiveSyncShards).toEqual([]);
      });
    });
  });

  describe('created', () => {
    describe('when node prop exists', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets nodeData to the correct node', () => {
        expect(wrapper.vm.nodeData.id).toBe(wrapper.vm.node.id);
      });
    });

    describe('when node prop does not exist', () => {
      beforeEach(() => {
        propsData.node = null;
        createComponent();
      });

      it('sets nodeData to the default node data', () => {
        expect(wrapper.vm.nodeData).not.toBeNull();
        expect(wrapper.vm.nodeData.id).not.toBe(MOCK_NODE.id);
      });
    });
  });
});
