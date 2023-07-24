import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventCreated from '~/contribution_events/components/contribution_event/contribution_event_created.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { TARGET_TYPE_EPIC, TARGET_TYPE_WORK_ITEM } from 'ee/contribution_events/constants';
import {
  eventEpicCreated,
  eventTestCaseCreated,
  eventRequirementCreated,
  eventObjectiveCreated,
  eventKeyResultCreated,
} from '../../utils';

describe('ContributionEventCreated', () => {
  let wrapper;

  const createComponent = ({ propsData }) => {
    wrapper = shallowMountExtended(ContributionEventCreated, {
      propsData,
    });
  };

  describe(`when event type is ${TARGET_TYPE_EPIC}`, () => {
    it('renders `ContributionEventBase` with correct props', () => {
      const event = eventEpicCreated();
      createComponent({ propsData: { event } });

      expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
        event,
        message: 'Opened Epic %{targetLink} in %{resourceParentLink}.',
        iconName: 'status_open',
        iconClass: 'gl-text-green-500',
      });
    });
  });

  describe(`when event target type is ${TARGET_TYPE_WORK_ITEM}`, () => {
    describe.each`
      event                        | expectedMessage
      ${eventTestCaseCreated()}    | ${'Opened test case %{targetLink} in %{resourceParentLink}.'}
      ${eventRequirementCreated()} | ${'Opened requirement %{targetLink} in %{resourceParentLink}.'}
      ${eventObjectiveCreated()}   | ${'Opened objective %{targetLink} in %{resourceParentLink}.'}
      ${eventKeyResultCreated()}   | ${'Opened key result %{targetLink} in %{resourceParentLink}.'}
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
