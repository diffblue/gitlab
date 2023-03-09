import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoReplicableStatus from 'ee/geo_replicable/components/geo_replicable_status.vue';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import {
  FILTER_STATES,
  STATUS_ICON_NAMES,
  STATUS_ICON_CLASS,
  DEFAULT_STATUS,
} from 'ee/geo_replicable/constants';

describe('GeoReplicableStatus', () => {
  let wrapper;

  const defaultProps = {
    status: FILTER_STATES.SYNCED.value,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(GeoReplicableStatus, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findStatusWrapper = () => wrapper.findByTestId('replicable-item-status');
  const findStatusIcon = () => findStatusWrapper().findComponent(GlIcon);
  const findStatusText = () => findStatusWrapper().find('span');

  describe.each`
    status
    ${FILTER_STATES.SYNCED.value}
    ${FILTER_STATES.PENDING.value}
    ${FILTER_STATES.FAILED.value}
    ${DEFAULT_STATUS}
  `('template', ({ status }) => {
    beforeEach(() => {
      createComponent({ status });
    });

    describe(`with status set to ${status}`, () => {
      it(`adds ${STATUS_ICON_CLASS[status]} to status wrapper`, () => {
        expect(findStatusWrapper().classes(STATUS_ICON_CLASS[status])).toBe(true);
      });

      it(`sets the status icon to ${STATUS_ICON_NAMES[status]}`, () => {
        expect(findStatusIcon().props('name')).toBe(STATUS_ICON_NAMES[status]);
      });

      it(`sets the status text to ${capitalizeFirstCharacter(status)}`, () => {
        expect(findStatusText().text()).toBe(capitalizeFirstCharacter(status));
      });
    });
  });
});
