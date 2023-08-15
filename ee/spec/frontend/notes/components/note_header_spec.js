import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NoteHeader from '~/notes/components/note_header.vue';

Vue.use(Vuex);

describe('NoteHeader component', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMountExtended(NoteHeader, {
      store: new Vuex.Store(),
      propsData: { ...props },
    });
  };

  it('shows internal note badge tooltip for group context when isInternalNote is true for epics', () => {
    createComponent({ isInternalNote: true, noteableType: 'epic' });

    expect(wrapper.findByTestId('internal-note-indicator').attributes('title')).toBe(
      'This internal note will always remain confidential',
    );
  });
});
