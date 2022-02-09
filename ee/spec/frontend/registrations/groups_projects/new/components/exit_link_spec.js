import { shallowMount } from '@vue/test-utils';
import ExitLink from 'ee/registrations/groups_projects/new/components/exit_link.vue';
import eventHub from 'ee/registrations/groups_projects/new/event_hub';

describe('ExitLink', () => {
  let wrapper;

  const EXIT_PATH = '/users/sign_up/groups_projects/exit';

  const findLink = () => wrapper.find('[data-testid="exit-link"]');

  const createComponent = () => {
    wrapper = shallowMount(ExitLink, {
      provide: {
        exitPath: EXIT_PATH,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the component is mounted', () => {
    it('displays a link', () => {
      expect(findLink().exists()).toBe(true);
      expect(findLink().attributes('href')).toBe(EXIT_PATH);
    });
  });

  describe('when the link is clicked', () => {
    beforeEach(() => {
      findLink().vm.$emit('click');
    });

    it('disables the link', () => {
      expect(findLink().attributes('disabled')).toBe('true');
    });
  });

  describe('when the `verificationCompleted` event is emitted', () => {
    beforeEach(() => {
      eventHub.$emit('verificationCompleted');
    });

    it('hides the link', () => {
      expect(findLink().exists()).toBe(false);
    });
  });
});
