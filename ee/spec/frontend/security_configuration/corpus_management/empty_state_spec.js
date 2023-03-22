import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import EmptyState from 'ee/security_configuration/corpus_management/components/empty_state.vue';

const TEST_CORPUS_HELP_PATH = '/docs/corpus-management';
const TEST_EMPTY_STATE_SVG_PATH = '/illustrations/no_commits.svg';

describe('EE - CorpusManagement - EmptyState', () => {
  let wrapper;
  const testButton = '<button>Perform action</button>';

  const createComponent = (options = {}) => {
    wrapper = shallowMount(EmptyState, {
      provide: {
        corpusHelpPath: TEST_CORPUS_HELP_PATH,
        emptyStateSvgPath: TEST_EMPTY_STATE_SVG_PATH,
      },
      slots: {
        actions: testButton,
      },
      stubs: {
        GlEmptyState,
      },
      ...options,
    });
  };

  it('should render correct content', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});
