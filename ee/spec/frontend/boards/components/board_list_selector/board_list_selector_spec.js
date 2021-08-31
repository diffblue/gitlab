import MockAdapter from 'axios-mock-adapter';
import BoardListSelector from 'ee/boards/components/boards_list_selector/';
import mountComponent from 'helpers/vue_mount_component_helper';
import { mockAssigneesList } from 'jest/boards/mock_data';
import { TEST_HOST } from 'spec/test_constants';
import { createStore } from '~/boards/stores';
import boardsStore from '~/boards/stores/boards_store';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/flash');

describe('BoardListSelector', () => {
  const dummyEndpoint = `${TEST_HOST}/users.json`;

  const createComponent = () =>
    mountComponent(BoardListSelector, {
      listPath: dummyEndpoint,
      listType: 'assignees',
    });

  let vm;
  let mock;

  boardsStore.create();
  boardsStore.state.assignees = [];

  beforeEach(() => {
    mock = new MockAdapter(axios);

    vm = createComponent();
    vm.vuexStore = createStore();
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.loading).toBe(true);
      expect(vm.store).toBe(boardsStore);
    });
  });

  describe('methods', () => {
    describe('loadList', () => {
      it('calls axios.get and sets response to store.state.assignees', (done) => {
        mock.onGet(dummyEndpoint).reply(200, mockAssigneesList);
        boardsStore.state.assignees = [];

        vm.loadList()
          .then(() => {
            expect(vm.loading).toBe(false);
            expect(vm.store.state.assignees.length).toBe(mockAssigneesList.length);
          })
          .then(done)
          .catch(done.fail);
      });

      it('does not call axios.get when store.state.assignees is not empty', (done) => {
        jest.spyOn(axios, 'get').mockReturnValue(Promise.resolve());
        boardsStore.state.assignees = mockAssigneesList;

        vm.loadList()
          .then(() => {
            expect(axios.get).not.toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });

      it('calls axios.get and shows Flash error when request fails', (done) => {
        mock.onGet(dummyEndpoint).replyOnce(500, {});
        boardsStore.state.assignees = [];

        vm.loadList()
          .then(() => {
            expect(vm.loading).toBe(false);
            expect(createFlash).toHaveBeenCalledWith({
              message: 'Something went wrong while fetching assignees list',
            });
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('handleItemClick', () => {
      it('creates new list in a store instance', () => {
        jest.spyOn(vm.vuexStore, 'dispatch').mockReturnValue({});
        const assignee = mockAssigneesList[0];

        expect(vm.vuexStore.getters.getListByTitle(assignee.name)).not.toBeDefined();
        vm.handleItemClick(assignee);

        expect(vm.vuexStore.dispatch).toHaveBeenCalledWith('createList', {
          assigneeId: 'gid://gitlab/User/2',
        });
      });
    });
  });
});
