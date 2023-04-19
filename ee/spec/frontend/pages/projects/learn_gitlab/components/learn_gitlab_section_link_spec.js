import { GlPopover, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import eventHub from '~/invite_members/event_hub';
import LearnGitlabSectionLink from 'ee/pages/projects/learn_gitlab/components/learn_gitlab_section_link.vue';
import { ACTION_LABELS } from 'ee/pages/projects/learn_gitlab/constants';
import { LEARN_GITLAB } from 'ee/invite_members/constants';

const defaultAction = 'gitWrite';
const defaultProps = {
  title: 'Create Repository',
  description: 'Some description',
  url: 'https://example.com',
  completed: false,
  enabled: true,
};

const openInNewTabProps = {
  url: 'https://docs.gitlab.com/ee/user/application_security/security_dashboard/',
  openInNewTab: true,
};

describe('Learn GitLab Section Link', () => {
  let wrapper;

  const createWrapper = (action = defaultAction, props = {}) => {
    wrapper = extendedWrapper(
      mount(LearnGitlabSectionLink, {
        propsData: { action, value: { ...defaultProps, ...props } },
      }),
    );
  };

  const findUncompletedLink = () => wrapper.find('[data-testid="uncompleted-learn-gitlab-link"]');
  const findDisabledLink = () => wrapper.findByTestId('disabled-learn-gitlab-link');
  const findPopoverTrigger = () => wrapper.findByTestId('contact-admin-popover-trigger');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverLink = () => findPopover().findComponent(GlLink);

  it('renders no icon when not completed', () => {
    createWrapper(undefined, { completed: false });

    expect(wrapper.find('[data-testid="completed-icon"]').exists()).toBe(false);
  });

  it('renders the completion icon when completed', () => {
    createWrapper(undefined, { completed: true });

    expect(wrapper.find('[data-testid="completed-icon"]').exists()).toBe(true);
  });

  it('renders no trial only when it is not required', () => {
    createWrapper();

    expect(wrapper.find('[data-testid="trial-only"]').exists()).toBe(false);
  });

  it('renders trial only when trial is required', () => {
    createWrapper('codeOwnersEnabled');

    expect(wrapper.find('[data-testid="trial-only"]').exists()).toBe(true);
  });

  describe('disabled links', () => {
    beforeEach(() => {
      createWrapper('trialStarted', { enabled: false });
    });

    it('renders text without a link', () => {
      expect(findDisabledLink().exists()).toBe(true);
      expect(findDisabledLink().text()).toBe(ACTION_LABELS.trialStarted.title);
      expect(findDisabledLink().attributes('href')).toBeUndefined();
    });

    it('renders a popover trigger with question icon', () => {
      expect(findPopoverTrigger().exists()).toBe(true);
      expect(findPopoverTrigger().props('icon')).toBe('question-o');
      expect(findPopoverTrigger().attributes('aria-label')).toBe(
        LearnGitlabSectionLink.i18n.contactAdmin,
      );
    });

    it('renders a popover', () => {
      expect(findPopoverTrigger().attributes('id')).toBe(findPopover().props('target'));
      expect(findPopover().props()).toMatchObject({
        placement: 'top',
        triggers: 'hover focus',
      });
    });

    it('renders default disabled message', () => {
      expect(findPopover().text()).toContain(LearnGitlabSectionLink.i18n.contactAdmin);
    });

    it('renders custom disabled message if provided', () => {
      createWrapper('trialStarted', { enabled: false, message: 'Custom message' });
      expect(findPopover().text()).toContain('Custom message');
    });

    it('renders a link inside the popover', () => {
      expect(findPopoverLink().exists()).toBe(true);
      expect(findPopoverLink().attributes('href')).toBe(defaultProps.url);
    });
  });

  describe('links marked with openInNewTab', () => {
    beforeEach(() => {
      createWrapper('licenseScanningRun', openInNewTabProps);
    });

    it('renders links with blank target', () => {
      const linkElement = findUncompletedLink();

      expect(linkElement.exists()).toBe(true);
      expect(linkElement.attributes('target')).toEqual('_blank');
    });

    it('tracks the click', () => {
      const trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);

      findUncompletedLink().trigger('click');

      expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_link', {
        label: 'scan_dependencies_for_licenses',
      });

      unmockTracking();
    });
  });

  describe('clicking the link to open the invite_members modal', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation();

      createWrapper('userAdded', { url: '#' });
    });

    it('calls the eventHub', () => {
      findUncompletedLink().vm.$emit('click');

      expect(eventHub.$emit).toHaveBeenCalledWith('openModal', { source: LEARN_GITLAB });
    });

    it('tracks the click', () => {
      const trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);

      findUncompletedLink().trigger('click');

      expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_link', {
        label: 'invite_your_colleagues',
      });

      unmockTracking();
    });
  });
});
