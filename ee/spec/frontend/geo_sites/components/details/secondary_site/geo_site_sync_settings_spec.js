import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteSyncSettings from 'ee/geo_sites/components/details/secondary_site/geo_site_sync_settings.vue';
import { MOCK_SECONDARY_SITE } from 'ee_jest/geo_sites/mock_data';

describe('GeoSiteSyncSettings', () => {
  let wrapper;

  const defaultProps = {
    site: MOCK_SECONDARY_SITE,
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(GeoSiteSyncSettings, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

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
          createComponent({ site: { selectiveSyncType } });
        });

        it(`renders correctly when selectiveSyncType is ${selectiveSyncType}`, () => {
          expect(findSyncType().text()).toBe(text);
        });
      });

      describe('with no timestamp info', () => {
        beforeEach(() => {
          createComponent({ site: { lastEventTimestamp: null, cursorLastEventTimestamp: null } });
        });

        it('does not render the sync status event info', () => {
          expect(findSyncStatusEventInfo().exists()).toBe(false);
        });
      });

      describe('with timestamp info', () => {
        beforeEach(() => {
          createComponent({
            site: {
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
