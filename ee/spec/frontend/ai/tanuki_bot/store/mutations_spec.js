import * as types from 'ee/ai/tanuki_bot/store/mutation_types';
import mutations from 'ee/ai/tanuki_bot/store/mutations';
import createState from 'ee/ai/tanuki_bot/store/state';
import { MESSAGE_TYPES, ERROR_MESSAGE } from 'ee/ai/tanuki_bot/constants';
import { MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE } from '../mock_data';

describe('TanukiBot Store Mutations', () => {
  let state;
  beforeEach(() => {
    state = createState();
  });

  describe('SET_LOADING', () => {
    it('sets loading to passed boolean', () => {
      mutations[types.SET_LOADING](state, true);

      expect(state.loading).toBe(true);
    });
  });

  describe('ADD_USER_MESSAGE', () => {
    it('pushes a message to the messages array with type: User', () => {
      mutations[types.ADD_USER_MESSAGE](state, MOCK_USER_MESSAGE.content);

      expect(state.messages).toStrictEqual([{ id: 0, ...MOCK_USER_MESSAGE }]);
    });
  });

  describe('ADD_TANUKI_MESSAGE', () => {
    it('pushes a message object to the messages array with type: Tanuki', () => {
      mutations[types.ADD_TANUKI_MESSAGE](state, MOCK_TANUKI_MESSAGE);

      expect(state.messages).toStrictEqual([{ id: 0, ...MOCK_TANUKI_MESSAGE }]);
    });
    it('correctly sets content in backwards compatible manner', () => {
      mutations[types.ADD_TANUKI_MESSAGE](state, { ...MOCK_TANUKI_MESSAGE, msg: 'test' });

      expect(state.messages).toStrictEqual([{ id: 0, ...MOCK_TANUKI_MESSAGE }]);
    });
  });

  describe('ADD_ERROR_MESSAGE', () => {
    it('pushes an error message to the messages array with type: Tanuki', () => {
      mutations[types.ADD_ERROR_MESSAGE](state);

      expect(state.messages).toStrictEqual([
        { id: 0, role: MESSAGE_TYPES.TANUKI, content: ERROR_MESSAGE },
      ]);
    });
  });
});
