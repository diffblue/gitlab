import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteSecondaryOtherInfo from 'ee/geo_sites/components/details/secondary_site/geo_site_secondary_other_info.vue';
import { MOCK_SECONDARY_SITE } from 'ee_jest/geo_sites/mock_data';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

// Dates come from the backend in seconds, we mimic that here.
const MOCK_JUST_NOW = new Date().getTime() / 1000;

describe('GeoSiteSecondaryOtherInfo', () => {
  let wrapper;

  const defaultProps = {
    site: MOCK_SECONDARY_SITE,
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(GeoSiteSecondaryOtherInfo, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: { GlSprintf, TimeAgo },
    });
  };

  const findDbReplicationLag = () => wrapper.findByTestId('replication-lag');
  const findLastEvent = () => wrapper.findByTestId('last-event');
  const findLastCursorEvent = () => wrapper.findByTestId('last-cursor-event');
  const findStorageShards = () => wrapper.findByTestId('storage-shards');

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the db replication lag', () => {
        expect(findDbReplicationLag().exists()).toBe(true);
      });

      it('renders the last event', () => {
        expect(findLastEvent().exists()).toBe(true);
      });

      it('renders the last cursor event', () => {
        expect(findLastCursorEvent().exists()).toBe(true);
      });

      it('renders the storage shards', () => {
        expect(findStorageShards().exists()).toBe(true);
      });
    });

    describe('conditionally', () => {
      describe.each`
        dbReplicationLagSeconds | text
        ${60}                   | ${'1m'}
        ${null}                 | ${'Unknown'}
      `(`db replication lag`, ({ dbReplicationLagSeconds, text }) => {
        beforeEach(() => {
          createComponent({ site: { dbReplicationLagSeconds } });
        });

        it(`renders correctly when dbReplicationLagSeconds is ${dbReplicationLagSeconds}`, () => {
          expect(findDbReplicationLag().text()).toBe(text);
        });
      });

      describe.each`
        storageShardsMatch | text
        ${true}            | ${'OK'}
        ${false}           | ${'Does not match the primary storage configuration'}
        ${null}            | ${'Unknown'}
      `(`storage shards`, ({ storageShardsMatch, text }) => {
        beforeEach(() => {
          createComponent({ site: { storageShardsMatch } });
        });

        it(`renders correctly when storageShardsMatch is ${storageShardsMatch}`, () => {
          expect(findStorageShards().text()).toBe(text);
        });
      });

      describe.each`
        lastEvent                                                | text
        ${{ lastEventId: null, lastEventTimestamp: null }}       | ${'Unknown'}
        ${{ lastEventId: 1, lastEventTimestamp: 0 }}             | ${'1'}
        ${{ lastEventId: 1, lastEventTimestamp: MOCK_JUST_NOW }} | ${'1 just now'}
      `(`last event`, ({ lastEvent, text }) => {
        beforeEach(() => {
          createComponent({ site: { ...lastEvent } });
        });

        it(`renders correctly when lastEventId is ${lastEvent.lastEventId} and lastEventTimestamp is ${lastEvent.lastEventTimestamp}`, () => {
          expect(findLastEvent().text().replace(/\s+/g, ' ')).toBe(text);
        });
      });

      describe.each`
        lastCursorEvent                                                      | text
        ${{ cursorLastEventId: null, cursorLastEventTimestamp: null }}       | ${'Unknown'}
        ${{ cursorLastEventId: 1, cursorLastEventTimestamp: 0 }}             | ${'1'}
        ${{ cursorLastEventId: 1, cursorLastEventTimestamp: MOCK_JUST_NOW }} | ${'1 just now'}
      `(`last cursor event`, ({ lastCursorEvent, text }) => {
        beforeEach(() => {
          createComponent({ site: { ...lastCursorEvent } });
        });

        it(`renders correctly when cursorLastEventId is ${lastCursorEvent.cursorLastEventId} and cursorLastEventTimestamp is ${lastCursorEvent.cursorLastEventTimestamp}`, () => {
          expect(findLastCursorEvent().text().replace(/\s+/g, ' ')).toBe(text);
        });
      });
    });
  });
});
