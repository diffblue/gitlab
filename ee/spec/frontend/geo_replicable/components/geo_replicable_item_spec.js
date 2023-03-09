import { GlLink, GlButton } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoReplicableItem from 'ee/geo_replicable/components/geo_replicable_item.vue';
import GeoReplicableStatus from 'ee/geo_replicable/components/geo_replicable_status.vue';
import GeoReplicableTimeAgo from 'ee/geo_replicable/components/geo_replicable_time_ago.vue';
import { ACTION_TYPES } from 'ee/geo_replicable/constants';
import { getStoreConfig } from 'ee/geo_replicable/store';
import { MOCK_BASIC_FETCH_DATA_MAP, MOCK_REPLICABLE_TYPE } from '../mock_data';

Vue.use(Vuex);

describe('GeoReplicableItem', () => {
  let wrapper;
  const mockReplicable = MOCK_BASIC_FETCH_DATA_MAP[0];

  const actionSpies = {
    initiateReplicableSync: jest.fn(),
  };

  const defaultProps = {
    name: mockReplicable.name,
    projectId: mockReplicable.projectId,
    syncStatus: mockReplicable.state,
    lastSynced: mockReplicable.lastSyncedAt,
    lastVerified: mockReplicable.verifiedAt,
  };

  const createComponent = (props = {}, state = {}) => {
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

  describe('template', () => {
    describe('by default', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders GeoReplicableStatus', () => {
        expect(findReplicableItemSyncStatus().exists()).toBe(true);
      });
    });

    describe('with projectId', () => {
      beforeEach(() => {
        createComponent({ projectId: mockReplicable.projectId });
      });

      it('GlLink renders correctly', () => {
        expect(findReplicableItemLink().exists()).toBe(true);
        expect(findReplicableItemLink().text()).toBe(mockReplicable.name);
        expect(findReplicableItemLink().attributes('href')).toBe(`/${mockReplicable.name}`);
      });

      describe('Resync Button', () => {
        it('renders', () => {
          expect(findResyncButton().exists()).toBe(true);
        });

        it('calls initiateReplicableSync when clicked', () => {
          findResyncButton().vm.$emit('click');

          expect(actionSpies.initiateReplicableSync).toHaveBeenCalledWith(expect.any(Object), {
            projectId: mockReplicable.projectId,
            name: mockReplicable.name,
            action: ACTION_TYPES.RESYNC,
          });
        });
      });
    });

    describe('without projectId', () => {
      beforeEach(() => {
        createComponent({ projectId: null });
      });

      it('renders GeoReplicableStatus', () => {
        expect(findReplicableItemSyncStatus().exists()).toBe(true);
      });

      it('Text title renders correctly', () => {
        expect(findReplicableItemNoLinkText().exists()).toBe(true);
        expect(findReplicableItemNoLinkText().text()).toBe(mockReplicable.name);
      });

      it('GlLink does not render', () => {
        expect(findReplicableItemLink().exists()).toBe(false);
      });

      it('ReSync Button does not render', () => {
        expect(findResyncButton().exists()).toBe(false);
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
});
