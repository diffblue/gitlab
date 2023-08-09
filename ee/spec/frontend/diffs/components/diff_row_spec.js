import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import DiffRow from '~/diffs/components/diff_row.vue';
import diffsModule from '~/diffs/store/modules';

Vue.use(Vuex);

describe('EE DiffRow', () => {
  let wrapper;

  const findIcon = () => wrapper.find('[data-testid="inlineFindingsIcon"]');

  const defaultProps = {
    fileHash: 'abc',
    filePath: 'abc',
    line: {},
    index: 0,
    isHighlighted: false,
    fileLineCoverage: () => ({}),
  };

  const createComponent = ({ props, state, actions, isLoggedIn = true }) => {
    const diffs = diffsModule();
    diffs.state = { ...diffs.state, ...state };
    diffs.actions = { ...diffs.actions, ...actions };

    const getters = { isLoggedIn: () => isLoggedIn };

    const store = new Vuex.Store({
      modules: { diffs },
      getters,
    });

    wrapper = shallowMount(DiffRow, {
      propsData: { ...defaultProps, ...props },
      store,
      listeners: {
        enterdragging: () => {},
        stopdragging: () => {},
        showCommentForm: () => {},
        setHighlightedRow: () => {},
      },
    });
  };

  afterEach(() => {
    Object.values(DiffRow).forEach(({ cache }) => {
      if (cache) {
        cache.clear();
      }
    });
  });

  describe('with a new code quality violation', () => {
    beforeEach(() => {
      createComponent({
        props: { line: { right: { codequality: [{ severity: 'critical' }] } } },
      });
    });

    it('shows code quality gutter icon', () => {
      expect(findIcon().exists()).toBe(true);
    });
  });

  describe('with no new code quality violations', () => {
    beforeEach(() => {
      createComponent({
        props: { line: { right: { codequality: [] } } },
      });
    });

    it('does not show code quality gutter icon', () => {
      expect(findIcon().exists()).toBe(false);
    });
  });
});
