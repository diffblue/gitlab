import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerFullName from 'ee/ci/runner/components/runner_full_name.vue';

const mockId = 'gid://gitlab/Ci::Runner/99';

describe('RunnerFullName', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(RunnerFullName, {
      propsData: {
        ...props,
      },
    });
  };

  it.each`
    runner                                                              | expected
    ${null}                                                             | ${''}
    ${{ id: mockId }}                                                   | ${'#99'}
    ${{ id: mockId, shortSha: '1234567890' }}                           | ${'#99 (1234567890)'}
    ${{ id: mockId, description: 'My runner' }}                         | ${'#99 - My runner'}
    ${{ id: mockId, shortSha: '1234567890', description: 'My runner' }} | ${'#99 (1234567890) - My runner'}
  `('$runner renders "$expected"', ({ runner, expected }) => {
    createComponent({
      props: { runner },
    });

    expect(wrapper.text()).toBe(expected);
  });
});
