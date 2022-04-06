import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/vuex_shared/modules/modal/actions';
import * as types from '~/vuex_shared/modules/modal/mutation_types';

describe('Vuex ModalModule actions', () => {
  describe('open', () => {
    it('works', async () => {
      const data = { id: 7 };

      await testAction(actions.open, data, {}, [{ type: types.OPEN, payload: data }], []);
    });
  });

  describe('close', () => {
    it('works', async () => {
      await testAction(actions.close, null, {}, [{ type: types.CLOSE }], []);
    });
  });

  describe('show', () => {
    it('works', async () => {
      await testAction(actions.show, null, {}, [{ type: types.SHOW }], []);
    });
  });

  describe('hide', () => {
    it('works', async () => {
      await testAction(actions.hide, null, {}, [{ type: types.HIDE }], []);
    });
  });
});
