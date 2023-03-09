import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import { getDiffFileMock } from 'jest/diffs/mock_data/diff_file';
import DiffViewComponent from '~/diffs/components/diff_view.vue';

import createDiffsStore from '~/diffs/store/modules';

function createComponent({ withCodequality = true, provide = {} }) {
  const diffFile = getDiffFileMock();

  Vue.use(Vuex);

  const store = new Vuex.Store({
    modules: {
      diffs: createDiffsStore(),
    },
  });

  store.state.diffs.diffFiles = [diffFile];

  if (withCodequality) {
    store.state.diffs.codequalityDiff = {
      files: {
        [diffFile.file_path]: [
          { line: 1, description: 'Unexpected alert.', severity: 'minor' },
          {
            line: 3,
            description: 'Arrow function has too many statements (52). Maximum allowed is 30.',
            severity: 'minor',
          },
        ],
      },
    };
  }

  const wrapper = mount(DiffViewComponent, {
    store,
    propsData: {
      diffFile,
      diffLines: [],
    },
    provide,
  });

  return {
    wrapper,
    store,
  };
}

describe('EE DiffView', () => {
  let wrapper;

  describe('when there is diff data for the file', () => {
    beforeEach(() => {
      ({ wrapper } = createComponent({
        withCodequality: true,
      }));
    });

    it('has the with-codequality class', () => {
      expect(wrapper.classes('with-codequality')).toBe(true);
    });
  });

  describe('when there is no diff data for the file', () => {
    beforeEach(() => {
      ({ wrapper } = createComponent({ withCodequality: false }));
    });

    it('does not have the with-codequality class', () => {
      expect(wrapper.classes('with-codequality')).toBe(false);
    });
  });
});
