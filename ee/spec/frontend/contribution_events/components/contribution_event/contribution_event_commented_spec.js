import { mountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventCommented from '~/contribution_events/components/contribution_event/contribution_event_commented.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import ResourceParentLink from '~/contribution_events/components/resource_parent_link.vue';
import { TARGET_TYPE_EPIC } from 'ee/contribution_events/constants';
import { eventCommentedEpic } from '../../utils';

describe('ContributionEventCommented', () => {
  let wrapper;

  const createComponent = ({ propsData }) => {
    wrapper = mountExtended(ContributionEventCommented, {
      propsData,
    });
  };

  const findNoteableLink = (event) =>
    wrapper.findByRole('link', { name: event.noteable.reference_link_text });
  const findResourceParentLink = () => wrapper.findComponent(ResourceParentLink);
  const findContributionEventBase = () => wrapper.findComponent(ContributionEventBase);
  const findEventBody = () => wrapper.findByTestId('event-body');

  describe(`when event type is ${TARGET_TYPE_EPIC}`, () => {
    const event = eventCommentedEpic();

    beforeEach(() => {
      createComponent({ propsData: { event } });
    });

    it('renders `ContributionEventBase` with correct props', () => {
      expect(findContributionEventBase().props()).toMatchObject({
        event,
        iconName: 'comment',
      });
    });

    it('renders message', () => {
      expect(findEventBody().text()).toContain('Commented on Epic');
    });

    it('renders resource parent link', () => {
      expect(findResourceParentLink().props('event')).toEqual(event);
    });

    it('renders noteable link', () => {
      expect(findNoteableLink(event).attributes('href')).toBe(event.noteable.web_url);
    });

    it('renders first line of comment in markdown', () => {
      expect(wrapper.html()).toContain(event.noteable.first_line_in_markdown);
    });
  });
});
