import { GlLink } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
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
    initiateReplicableAction: jest.fn(),
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
  const findResyncButton = () => wrapper.findByTestId('geo-resync-item');
  const findReverifyButton = () => wrapper.findByTestId('geo-reverify-item');
  const findReplicableItemNoLinkText = () => findReplicableItemHeader().find('span');
  const findReplicableItemTimeAgos = () => wrapper.findAllComponents(GeoReplicableTimeAgo);
  const findReplicableTimeAgosDateStrings = () =>
    findReplicableItemTimeAgos().wrappers.map((w) => w.props('dateString'));
  const findReplicableTimeAgosDefaultTexts = () =>
    findReplicableItemTimeAgos().wrappers.map((w) => w.props('defaultText'));

  describe.each`
    geoRegistriesUpdateMutation | verificationEnabled
    ${false}                    | ${false}
    ${false}                    | ${true}
    ${true}                     | ${false}
    ${true}                     | ${true}
  `('template', ({ geoRegistriesUpdateMutation, verificationEnabled }) => {
    describe(`when graphqlFieldName is null, verificationEnabled is ${verificationEnabled} and feature flag geoRegistriesUpdateMutation is ${geoRegistriesUpdateMutation}`, () => {
      beforeEach(() => {
        createComponent(
          null,
          { graphqlFieldName: null, verificationEnabled },
          { geoRegistriesUpdateMutation },
        );
      });

      it('renders GeoReplicableStatus', () => {
        expect(findReplicableItemSyncStatus().exists()).toBe(true);
      });

      it('renders title as GlLink with correct link', () => {
        expect(findReplicableItemLink().attributes('href')).toBe(`/${mockReplicable.name}`);
      });

      it('does not render title as plain text', () => {
        expect(findReplicableItemNoLinkText().exists()).toBe(false);
      });

      it('renders Resync Button', () => {
        expect(findResyncButton().exists()).toBe(true);
      });

      it('does not render Reverify Button', () => {
        expect(findReverifyButton().exists()).toBe(false);
      });
    });
  });

  describe.each`
    geoRegistriesUpdateMutation | verificationEnabled | showResyncAction | showReverifyAction
    ${false}                    | ${false}            | ${false}         | ${false}
    ${false}                    | ${true}             | ${false}         | ${false}
    ${true}                     | ${false}            | ${true}          | ${false}
    ${true}                     | ${true}             | ${true}          | ${true}
  `(
    'template',
    ({
      geoRegistriesUpdateMutation,
      verificationEnabled,
      showResyncAction,
      showReverifyAction,
    }) => {
      describe(`when graphqlFieldName is ${MOCK_GRAPHQL_REGISTRY}, verificationEnabled is ${verificationEnabled} and feature flag geoRegistriesUpdateMutation is ${geoRegistriesUpdateMutation}`, () => {
        beforeEach(() => {
          createComponent(
            null,
            { graphqlFieldName: MOCK_GRAPHQL_REGISTRY, verificationEnabled },
            { geoRegistriesUpdateMutation },
          );
        });

        it('renders GeoReplicableStatus', () => {
          expect(findReplicableItemSyncStatus().exists()).toBe(true);
        });

        it('does not render title as a link', () => {
          expect(findReplicableItemLink().exists()).toBe(false);
        });

        it('renders title as plain text', () => {
          expect(findReplicableItemNoLinkText().text()).toBe(mockReplicable.name);
        });

        it(`${showResyncAction ? 'does' : 'does not'} render Resync Button`, () => {
          expect(findResyncButton().exists()).toBe(showResyncAction);
        });

        it(`${showReverifyAction ? 'does' : 'does not'} render Reverify Button`, () => {
          expect(findReverifyButton().exists()).toBe(showReverifyAction);
        });
      });
    },
  );

  describe('Resync button action', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls initiateReplicableAction when clicked', () => {
      findResyncButton().vm.$emit('click');

      expect(actionSpies.initiateReplicableAction).toHaveBeenCalledWith(expect.any(Object), {
        registryId: defaultProps.registryId,
        name: defaultProps.name,
        action: ACTION_TYPES.RESYNC,
      });
    });
  });

  describe('Reverify button action', () => {
    beforeEach(() => {
      createComponent(
        null,
        { graphqlFieldName: MOCK_GRAPHQL_REGISTRY, verificationEnabled: true },
        { geoRegistriesUpdateMutation: true },
      );
    });

    it('calls initiateReplicableAction when clicked', () => {
      findReverifyButton().vm.$emit('click');

      expect(actionSpies.initiateReplicableAction).toHaveBeenCalledWith(expect.any(Object), {
        registryId: defaultProps.registryId,
        name: defaultProps.name,
        action: ACTION_TYPES.REVERIFY,
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
