import { GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import NamespaceLimitsChangelog from 'ee/pages/admin/namespace_limits/components/namespace_limits_changelog.vue';

const sampleChangelogEntries = [
  {
    user_id: 1,
    username: 'admin',
    value: 150000,
    timestamp: 1689069917,
  },
  {
    user_id: 2,
    username: 'gitlab-bot',
    value: 0,
    timestamp: 1689067917,
  },
];

describe('NamespaceLimitsChangelog', () => {
  let wrapper;

  const findChangelogEntries = () => wrapper.findByTestId('changelog-entries');
  const findChangelogHeader = () => wrapper.findByText('Changelog');

  const createComponent = (props = {}) => {
    wrapper = mountExtended(NamespaceLimitsChangelog, {
      propsData: { entries: sampleChangelogEntries, ...props },
      stubs: { GlLink },
    });
  };
  const gitlabUrl = 'https://gitlab.com/';

  beforeEach(() => {
    gon.gitlab_url = gitlabUrl;
  });

  describe('when there are changelog entries', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders changelog entries links', () => {
      const changelogLinks = findChangelogEntries()
        .findAllComponents(GlLink)
        .wrappers.map((w) => w.attributes('href'));

      expect(changelogLinks).toStrictEqual([
        'https://gitlab.com/admin',
        'https://gitlab.com/gitlab-bot',
      ]);
    });

    it('renders changelog entries interpolated text', () => {
      const changelogTexts = findChangelogEntries()
        .findAll('li')
        .wrappers.map((w) => w.text().replace(/\s\s+/g, ' '));

      expect(changelogTexts).toStrictEqual([
        '2023-07-11 10:07:17 admin changed the limit to 150000 MiB',
        '2023-07-11 09:07:57 gitlab-bot changed the limit to NONE',
      ]);
    });

    it('renders changelog header', () => {
      expect(findChangelogHeader().exists()).toBe(true);
    });
  });

  describe('when there are no changelog entries', () => {
    beforeEach(() => {
      createComponent({ entries: [] });
    });

    it('does not render changelog entries section', () => {
      expect(findChangelogEntries().exists()).toBe(false);
    });

    it('does not render changelog header', () => {
      expect(findChangelogHeader().exists()).toBe(false);
    });
  });
});
