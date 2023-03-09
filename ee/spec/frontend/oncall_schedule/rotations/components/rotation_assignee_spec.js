import { GlAvatar, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RotationAssignee, {
  SHIFT_WIDTHS,
  TIME_DATE_FORMAT,
} from 'ee/oncall_schedules/components/rotations/components/rotation_assignee.vue';
import { getParticipantColor } from 'ee/oncall_schedules/utils/common_utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { formatDate } from '~/lib/utils/datetime_utility';
import { truncate } from '~/lib/utils/text_utility';
import { mockRotations } from '../../mocks/apollo_mock';

jest.mock('lodash/uniqueId', () => (prefix) => `${prefix}fakeUniqueId`);
jest.mock('~/lib/utils/color_utils');

describe('RotationAssignee', () => {
  let wrapper;

  const containerStyle = { width: SHIFT_WIDTHS.md, left: 0 };
  const assignee = mockRotations[0].shifts.nodes[0];
  const findToken = () => wrapper.findByTestId('rotation-assignee');
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findPopOver = () => wrapper.findComponent(GlPopover);
  const findStartsAt = () => wrapper.findByTestId('rotation-assignee-starts-at');
  const findEndsAt = () => wrapper.findByTestId('rotation-assignee-ends-at');
  const findName = () => wrapper.findByTestId('rotation-assignee-name');

  const formattedDate = (date) => {
    return formatDate(date, TIME_DATE_FORMAT);
  };
  const color = getParticipantColor(0);

  function createComponent({ props = {} } = {}) {
    wrapper = extendedWrapper(
      shallowMount(RotationAssignee, {
        propsData: {
          assignee: { ...assignee.participant },
          startsAt: assignee.startsAt,
          endsAt: assignee.endsAt,
          containerStyle,
          color,
          ...props,
        },
      }),
    );
  }

  beforeEach(() => {
    createComponent();
  });

  describe('rotation assignee token', () => {
    it('should render an assignee name and avatar', () => {
      const LARGE_SHIFT_WIDTH = 150;
      createComponent({ props: { containerStyle: { width: `${LARGE_SHIFT_WIDTH}px` } } });
      expect(findAvatar().props('src')).toBe(assignee.participant.user.avatarUrl);
      expect(findName().text()).toBe(assignee.participant.user.username);
    });

    it('truncate the rotation name on small screens', () => {
      createComponent({ props: { containerStyle: { width: `${SHIFT_WIDTHS.md}px` } } });

      expect(findName().text()).toBe(truncate(assignee.participant.user.username, 3));
    });

    it('hides the rotation name on mobile screens', () => {
      createComponent({ props: { containerStyle: { width: `${SHIFT_WIDTHS.sm}px` } } });
      expect(findName().exists()).toBe(false);
    });

    it('hides the avatar on the smallest screens', () => {
      createComponent({ props: { containerStyle: { width: `${SHIFT_WIDTHS.xs}px` } } });
      expect(findAvatar().exists()).toBe(false);
    });

    it('should render an assignee color based on the chevron skipping color palette', () => {
      const token = findToken();
      expect(token.attributes('style')).toBe('background-color: rgb(97, 122, 226);');
    });

    it('should render an assignee schedule and rotation information in a popover', () => {
      expect(findPopOver().attributes('target')).toBe('rotation-assignee-fakeUniqueId');
      expect(findStartsAt().text()).toContain(`Starts: ${formattedDate(assignee.startsAt)}`);
      expect(findEndsAt().text()).toContain(
        formattedDate(`Ends: ${formattedDate(assignee.endsAt)}`),
      );
    });
  });
});
