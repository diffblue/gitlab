import { GlFormInput, GlModal, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import NamespaceLimitsSection, {
  MODAL_ID,
} from 'ee/pages/admin/namespace_limits/components/namespace_limits_section.vue';

const sampleChangelogEntries = [
  {
    user_web_url: 'https://gitlab.com/admin',
    username: 'admin',
    limit: '150 GiB',
    date: '2023-04-05 19:14:00',
  },
  {
    user_web_url: 'https://gitlab.com/gitlab-bot',
    username: 'gitlab-bot',
    limit: '10 GiB',
    date: '2023-04-06 19:14:00',
  },
];

describe('NamespaceLimitsSection', () => {
  let wrapper;

  const defaultProps = {
    label: 'Set notifications limit',
    changelogEntries: sampleChangelogEntries,
  };
  const glModalDirective = jest.fn();

  const createComponent = (props = {}) => {
    wrapper = mountExtended(NamespaceLimitsSection, {
      propsData: { ...defaultProps, ...props },
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
    });
  };

  const findUpdateLimitButton = () => wrapper.findByText('Update limit');
  const findModal = () => wrapper.findComponent(GlModal);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findChangelogEntries = () => wrapper.findByTestId('changelog-entries');
  const findChangelogHeader = () => wrapper.findByText('Changelog');

  describe('interacting with modal', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('rendering form elements', () => {
      it('renders limit input and update limit button', () => {
        expect(findInput().exists()).toBe(true);
        expect(findUpdateLimitButton().exists()).toBe(true);
      });
    });
  });

  describe('update limit button', () => {
    beforeEach(() => {
      createComponent();
      findUpdateLimitButton().trigger('click');
    });

    it('shows a confirmation modal', () => {
      expect(findModal().props('modalId')).toBe(MODAL_ID);
      expect(glModalDirective).toHaveBeenCalledWith(MODAL_ID);
    });

    it('passes the correct attributes to modal primary action', () => {
      expect(findModal().props('actionPrimary')).toEqual({
        attributes: {
          variant: 'danger',
        },
        text: 'Confirm limits change',
      });
    });

    describe('changing limits', () => {
      it('emits limit-change event when modal is confirmed', () => {
        findInput().setValue(150);
        findModal().vm.$emit('primary');
        expect(wrapper.emitted('limit-change')).toStrictEqual([['150']]);
      });
    });
  });

  describe('changelog', () => {
    describe('when there are changelog entries', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders changelog entries links', () => {
        const changelogLinks = findChangelogEntries()
          .findAllComponents(GlLink)
          .wrappers.map((w) => w.attributes('href'));

        expect(changelogLinks).toStrictEqual(
          sampleChangelogEntries.map((item) => item.user_web_url),
        );
      });

      it('renders changelog entries interpolated text', () => {
        const changelogTexts = findChangelogEntries()
          .findAll('li')
          .wrappers.map((w) => w.text().replace(/\s\s+/g, ' '));

        const sampleChangelogInterpolatedText = sampleChangelogEntries.map(
          (item) => `${item.username} changed the limit to ${item.limit} at ${item.date}`,
        );

        expect(changelogTexts).toStrictEqual(sampleChangelogInterpolatedText);
      });

      it('renders changelog header', () => {
        expect(findChangelogHeader().exists()).toBe(true);
      });
    });

    describe('when there are no changelog entries', () => {
      beforeEach(() => {
        createComponent({ changelogEntries: [] });
      });

      it('does not render changelog entries section', () => {
        expect(findChangelogEntries().exists()).toBe(false);
      });

      it('does not render changelog header', () => {
        expect(findChangelogHeader().exists()).toBe(false);
      });
    });
  });
});
