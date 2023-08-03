import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventClosed from '~/contribution_events/components/contribution_event/contribution_event_closed.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { TARGET_TYPE_EPIC, TARGET_TYPE_WORK_ITEM } from 'ee/contribution_events/constants';
import {
  eventEpicClosed,
  eventTestCaseClosed,
  eventRequirementClosed,
  eventObjectiveClosed,
  eventKeyResultClosed,
} from '../../utils';

describe('ContributionEventClosed', () => {
  let wrapper;

  const createComponent = ({ propsData }) => {
    wrapper = shallowMountExtended(ContributionEventClosed, {
      propsData,
    });
  };

  describe(`when event type is ${TARGET_TYPE_EPIC}`, () => {
    it('renders `ContributionEventBase` with correct props', () => {
      const event = eventEpicClosed();
      createComponent({ propsData: { event } });

      expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
        event,
        message: 'Closed Epic %{targetLink} in %{resourceParentLink}.',
        iconName: 'epic-closed',
        iconClass: 'gl-text-blue-500',
      });
    });
  });

  describe(`when event target type is ${TARGET_TYPE_WORK_ITEM}`, () => {
    describe.each`
      event                       | expectedMessage
      ${eventTestCaseClosed()}    | ${'Closed test case %{targetLink} in %{resourceParentLink}.'}
      ${eventRequirementClosed()} | ${'Closed requirement %{targetLink} in %{resourceParentLink}.'}
      ${eventObjectiveClosed()}   | ${'Closed objective %{targetLink} in %{resourceParentLink}.'}
      ${eventKeyResultClosed()}   | ${'Closed key result %{targetLink} in %{resourceParentLink}.'}
    `('when issue type is $event.target.issue_type', ({ event, expectedMessage }) => {
      it('renders `ContributionEventBase` with correct props', () => {
        createComponent({ propsData: { event } });

        expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
          event,
          message: expectedMessage,
          iconName: 'status_closed',
          iconClass: 'gl-text-blue-500',
        });
      });
    });
  });
});
