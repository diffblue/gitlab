import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoReplicableTimeAgo from 'ee/geo_replicable/components/geo_replicable_time_ago.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

const MOCK_LABEL = 'Test Label';
const MOCK_DEFAULT_TEXT = 'Default Text';
const MOCK_JUST_NOW = new Date().toISOString();

describe('GeoReplicableTimeAgo', () => {
  let wrapper;

  const defaultProps = {
    label: MOCK_LABEL,
    dateString: MOCK_JUST_NOW,
    defaultText: MOCK_DEFAULT_TEXT,
    showDivider: false,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(GeoReplicableTimeAgo, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
        TimeAgo,
      },
    });
  };

  const findReplicableTimeAgo = () => wrapper.findByTestId('replicable-time-ago');

  describe.each`
    dateString       | showDivider | expectedText
    ${MOCK_JUST_NOW} | ${true}     | ${`${MOCK_LABEL} just now`}
    ${MOCK_JUST_NOW} | ${false}    | ${`${MOCK_LABEL} just now`}
    ${null}          | ${true}     | ${`${MOCK_LABEL} ${MOCK_DEFAULT_TEXT}`}
    ${null}          | ${false}    | ${`${MOCK_LABEL} ${MOCK_DEFAULT_TEXT}`}
  `('template', ({ dateString, showDivider, expectedText }) => {
    beforeEach(() => {
      createComponent({ dateString, showDivider });
    });

    describe(`with dateString is ${dateString} and showDivider is ${showDivider}`, () => {
      it(`sets Replicable Time Ago text to ${expectedText}`, () => {
        expect(findReplicableTimeAgo().text()).toBe(expectedText);
      });

      it(`does${showDivider ? '' : ' not'} show right border`, () => {
        expect(findReplicableTimeAgo().find('span').classes('gl-border-r-1')).toBe(showDivider);
        expect(findReplicableTimeAgo().find('span').classes('gl-border-r-solid')).toBe(showDivider);
      });
    });
  });
});
