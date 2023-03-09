import { GlTabs } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AuditEventsApp from 'ee/audit_events/components/audit_events_app.vue';
import Tracking from '~/tracking';

describe('AuditEventsApp', () => {
  let wrapper;

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findStreamsTab = () => wrapper.findByTestId('streams-tab');

  const createComponent = (provide = { isProject: false, showStreams: false }) => {
    wrapper = shallowMountExtended(AuditEventsApp, {
      provide,
    });
  };

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
  });

  describe('tabs', () => {
    it.each`
      isProject | showStreams | showTabs
      ${true}   | ${true}     | ${false}
      ${true}   | ${false}    | ${false}
      ${false}  | ${true}     | ${true}
      ${false}  | ${false}    | ${false}
    `(
      'when isProject is $isProject and showStreams $showStreams then showTabs should be $showTabs',
      ({ isProject, showStreams, showTabs }) => {
        createComponent({ isProject, showStreams });

        expect(findTabs().exists()).toBe(showTabs);
      },
    );

    it('sends tracking data when the streaming tab is clicked', () => {
      createComponent({ isProject: false, showStreams: true });

      findStreamsTab().vm.$emit('click');

      expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_tab', {
        label: 'audit_events_streams_tab',
      });
    });
  });
});
