import { GlLink, GlButton } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoReplicableItem from 'ee/geo_replicable/components/geo_replicable_item.vue';
import GeoReplicableStatus from 'ee/geo_replicable/components/geo_replicable_status.vue';
import GeoReplicableTimeAgo from 'ee/geo_replicable/components/geo_replicable_time_ago.vue';
import { ACTION_TYPES } from 'ee/geo_replicable/constants';
import { getStoreConfig } from 'ee/geo_replicable/store';
import {
  MOCK_BASIC_FETCH_DATA_MAP,
  MOCK_REPLICABLE_TYPE,
  MOCK_GRAPHQL_REGISTRY,
} from '../mock_data';

Vue.use(Vuex);

describe('GeoReplicableItem', () => {
  let wrapper;
  const mockReplicable = MOCK_BASIC_FETCH_DATA_MAP[0];

  const actionSpies = {
    initiateReplicableSync: jest.fn(),
  };

  const defaultProps = {
    name: mockReplicable.name,
    registryId: mockReplicable.id,
    syncStatus: mockReplicable.state,
    lastSynced: mockReplicable.lastSyncedAt,
    lastVerified: mockReplicable.verifiedAt,
  };

  const createComponent = (props = {}, state = {}, featureFlags = {}) => {
    const store = new Vuex.Store({
      ...getStoreConfig({ replicableType: MOCK_REPLICABLE_TYPE, graphqlFieldName: null, ...state }),
      actions: actionSpies,
    });

    wrapper = shallowMountExtended(GeoReplicableItem, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: { glFeatures: { ...featureFlags } },
    });
  };

  const findReplicableItemHeader = () => wrapper.findByTestId('replicable-item-header');
  const findReplicableItemSyncStatus = () =>
    findReplicableItemHeader().findComponent(GeoReplicableStatus);
  const findReplicableItemLink = () => findReplicableItemHeader().findComponent(GlLink);
  const findResyncButton = () => findReplicableItemHeader().findComponent(GlButton);
  const findReplicableItemNoLinkText = () => findReplicableItemHeader().find('span');
  const findReplicableItemTimeAgos = () => wrapper.findAllComponents(GeoReplicableTimeAgo);
  const findReplicableTimeAgosDateStrings = () =>
    findReplicableItemTimeAgos().wrappers.map((w) => w.props('dateString'));
  const findReplicableTimeAgosDefaultTexts = () =>
    findReplicableItemTimeAgos().wrappers.map((w) => w.props('defaultText'));

  describe.each`
    graphqlFieldName         | geoRegistriesUpdateMutation | link                         | nonLink                | showAction
    ${null}                  | ${false}                    | ${`/${mockReplicable.name}`} | ${false}               | ${true}
    ${null}                  | ${true}                     | ${`/${mockReplicable.name}`} | ${false}               | ${true}
    ${MOCK_GRAPHQL_REGISTRY} | ${false}                    | ${false}                     | ${mockReplicable.name} | ${false}
    ${MOCK_GRAPHQL_REGISTRY} | ${true}                     | ${false}                     | ${mockReplicable.name} | ${true}
  `('template', ({ graphqlFieldName, geoRegistriesUpdateMutation, link, nonLink, showAction }) => {
    describe(`when graphqlFieldName is ${graphqlFieldName} and feature flag geoRegistriesUpdateMutation is ${geoRegistriesUpdateMutation}`, () => {
      beforeEach(() => {
        createComponent(null, { graphqlFieldName }, { geoRegistriesUpdateMutation });
      });

      it('renders GeoReplicableStatus', () => {
        expect(findReplicableItemSyncStatus().exists()).toBe(true);
      });

      it(`does ${link ? '' : 'not '}render GlLink with correct link`, () => {
        expect(
          findReplicableItemLink().exists() && findReplicableItemLink().attributes('href'),
        ).toBe(link);
      });

      it(`does ${nonLink ? '' : 'not '}render No link title`, () => {
        expect(
          findReplicableItemNoLinkText().exists() && findReplicableItemNoLinkText().text(),
        ).toBe(nonLink);
      });

      it(`does ${showAction ? '' : 'not '}render Resync Button`, () => {
        expect(findResyncButton().exists()).toBe(showAction);
      });
    });
  });

  describe('Resync button action', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls initiateReplicableSync when clicked', () => {
      findResyncButton().vm.$emit('click');

      expect(actionSpies.initiateReplicableSync).toHaveBeenCalledWith(expect.any(Object), {
        registryId: defaultProps.registryId,
        name: defaultProps.name,
        action: ACTION_TYPES.RESYNC,
      });
    });
  });

  describe('when verificationEnabled is true', () => {
    beforeEach(() => {
      createComponent(null, { verificationEnabled: 'true' });
    });

    it('renders GeoReplicableTimeAgo component for each element in timeAgoArray', () => {
      expect(findReplicableItemTimeAgos().length).toBe(2);
    });

    it('passes the correct date strings to the GeoReplicableTimeAgo component', () => {
      expect(findReplicableTimeAgosDateStrings().length).toBe(2);
      expect(findReplicableTimeAgosDateStrings()).toStrictEqual([
        mockReplicable.lastSyncedAt,
        mockReplicable.verifiedAt,
      ]);
    });

    it('passes the correct date defaultTexts to the GeoReplicableTimeAgo component', () => {
      expect(findReplicableTimeAgosDefaultTexts().length).toBe(2);
      expect(findReplicableTimeAgosDefaultTexts()).toStrictEqual([
        GeoReplicableItem.i18n.unknown,
        GeoReplicableItem.i18n.unknown,
      ]);
    });
  });

  describe('when verificationEnabled is false', () => {
    beforeEach(() => {
      createComponent(null, { verificationEnabled: 'false' });
    });

    it('renders GeoReplicableTimeAgo component for each element in timeAgoArray', () => {
      expect(findReplicableItemTimeAgos().length).toBe(2);
    });

    it('passes the correct date strings to the GeoReplicableTimeAgo component', () => {
      expect(findReplicableTimeAgosDateStrings().length).toBe(2);
      expect(findReplicableTimeAgosDateStrings()).toStrictEqual([
        mockReplicable.lastSyncedAt,
        mockReplicable.verifiedAt,
      ]);
    });

    it('passes the correct date defaultTexts to the GeoReplicableTimeAgo component', () => {
      expect(findReplicableTimeAgosDefaultTexts().length).toBe(2);
      expect(findReplicableTimeAgosDefaultTexts()).toStrictEqual([
        GeoReplicableItem.i18n.unknown,
        GeoReplicableItem.i18n.nA,
      ]);
    });
  });
});
