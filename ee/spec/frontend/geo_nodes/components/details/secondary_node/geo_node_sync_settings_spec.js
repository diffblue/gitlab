import { shallowMount } from '@vue/test-utils';
import GeoNodeSyncSettings from 'ee/geo_nodes/components/details/secondary_node/geo_node_sync_settings.vue';
import { MOCK_SECONDARY_NODE } from 'ee_jest/geo_nodes/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('GeoNodeSyncSettings', () => {
  let wrapper;

  const defaultProps = {
    node: MOCK_SECONDARY_NODE,
  };

  const createComponent = (props) => {
    wrapper = extendedWrapper(
      shallowMount(GeoNodeSyncSettings, {
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findSyncType = () => wrapper.findByTestId('sync-type');
  const findSyncStatusEventInfo = () => wrapper.findByTestId('sync-status-event-info');

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the sync type', () => {
        expect(findSyncType().exists()).toBe(true);
      });
    });

    describe('conditionally', () => {
      describe.each`
        selectiveSyncType | text
        ${null}           | ${'Full'}
        ${'namespaces'}   | ${'Selective (groups)'}
        ${'shards'}       | ${'Selective (shards)'}
      `(`sync type`, ({ selectiveSyncType, text }) => {
        beforeEach(() => {
          createComponent({ node: { selectiveSyncType } });
        });

        it(`renders correctly when selectiveSyncType is ${selectiveSyncType}`, () => {
          expect(findSyncType().text()).toBe(text);
        });
      });

      describe('with no timestamp info', () => {
        beforeEach(() => {
          createComponent({ node: { lastEventTimestamp: null, cursorLastEventTimestamp: null } });
        });

        it('does not render the sync status event info', () => {
          expect(findSyncStatusEventInfo().exists()).toBe(false);
        });
      });

      describe('with timestamp info', () => {
        beforeEach(() => {
          createComponent({
            node: {
              lastEventTimestamp: 1511255300,
              lastEventId: 10,
              cursorLastEventTimestamp: 1511255200,
              cursorLastEventId: 9,
            },
          });
        });

        it('does render the sync status event info', () => {
          expect(findSyncStatusEventInfo().exists()).toBe(true);
          expect(findSyncStatusEventInfo().text()).toBe('20 seconds (1 events)');
        });
      });
    });
  });
});
