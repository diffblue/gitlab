import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventReopened from '~/contribution_events/components/contribution_event/contribution_event_reopened.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { TARGET_TYPE_EPIC, TARGET_TYPE_WORK_ITEM } from 'ee/contribution_events/constants';
import {
  eventEpicReopened,
  eventTestCaseReopened,
  eventRequirementReopened,
  eventObjectiveReopened,
  eventKeyResultReopened,
} from '../../utils';

describe('ContributionEventReopened', () => {
  let wrapper;

  const createComponent = ({ propsData }) => {
    wrapper = shallowMountExtended(ContributionEventReopened, {
      propsData,
    });
  };

  describe(`when event type is ${TARGET_TYPE_EPIC}`, () => {
    it('renders `ContributionEventBase` with correct props', () => {
      const event = eventEpicReopened();
      createComponent({ propsData: { event } });

      expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
        event,
        message: 'Reopened Epic %{targetLink} in %{resourceParentLink}.',
        iconName: 'status_open',
        iconClass: 'gl-text-green-500',
      });
    });
  });

  describe(`when event target type is ${TARGET_TYPE_WORK_ITEM}`, () => {
    describe.each`
      event                         | expectedMessage
      ${eventTestCaseReopened()}    | ${'Reopened test case %{targetLink} in %{resourceParentLink}.'}
      ${eventRequirementReopened()} | ${'Reopened requirement %{targetLink} in %{resourceParentLink}.'}
      ${eventObjectiveReopened()}   | ${'Reopened objective %{targetLink} in %{resourceParentLink}.'}
      ${eventKeyResultReopened()}   | ${'Reopened key result %{targetLink} in %{resourceParentLink}.'}
    `('when issue type is $event.target.issue_type', ({ event, expectedMessage }) => {
      it('renders `ContributionEventBase` with correct props', () => {
        createComponent({ propsData: { event } });

        expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
          event,
          message: expectedMessage,
          iconName: 'status_open',
          iconClass: 'gl-text-green-500',
        });
      });
    });
  });
});
