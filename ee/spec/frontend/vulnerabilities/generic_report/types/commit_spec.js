import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Commit from 'ee/vulnerabilities/components/generic_report/types/commit.vue';

const TEST_DATA = {
  value: '24922148',
};
const TEST_COMMIT_PATH_BASE = `/foo/bar`;
const TEST_COMMIT_PATH_PARAMETERS = '?baz=quz';
const TEST_COMMIT_PATH_TEMPLATE = `${TEST_COMMIT_PATH_BASE}/$COMMIT_SHA/${TEST_COMMIT_PATH_PARAMETERS}`;

describe('ee/vulnerabilities/components/generic_report/types/commit.vue', () => {
  let wrapper;

  const createWrapper = () => {
    return shallowMount(Commit, {
      propsData: TEST_DATA,
      provide: {
        commitPathTemplate: TEST_COMMIT_PATH_TEMPLATE,
      },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('links to the given commit hash', () => {
    expect(findLink().attributes('href')).toBe(
      `${TEST_COMMIT_PATH_BASE}/${TEST_DATA.value}/${TEST_COMMIT_PATH_PARAMETERS}`,
    );
  });

  it('shows the value as the link-text', () => {
    expect(findLink().text()).toBe(TEST_DATA.value);
  });
});
