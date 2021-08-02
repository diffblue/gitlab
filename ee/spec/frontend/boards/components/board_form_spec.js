import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import BoardForm from 'ee/boards/components/board_form.vue';
import createEpicBoardMutation from 'ee/boards/graphql/epic_board_create.mutation.graphql';
import destroyEpicBoardMutation from 'ee/boards/graphql/epic_board_destroy.mutation.graphql';
import updateEpicBoardMutation from 'ee/boards/graphql/epic_board_update.mutation.graphql';

import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';

import { formType } from '~/boards/constants';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  stripFinalUrlSegment: jest.requireActual('~/lib/utils/url_utility').stripFinalUrlSegment,
}));

Vue.use(Vuex);

const currentBoard = {
  id: 1,
  name: 'test',
  labels: [],
  milestone_id: undefined,
  assignee: {},
  assignee_id: undefined,
  weight: null,
  hide_backlog_list: false,
  hide_closed_list: false,
};

const defaultProps = {
  canAdminBoard: false,
  labelsPath: `${TEST_HOST}/labels/path`,
  labelsWebUrl: `${TEST_HOST}/-/labels`,
  currentBoard,
  currentPage: '',
};

describe('BoardForm', () => {
  let wrapper;
  let mutate;

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalActionPrimary = () => findModal().props('actionPrimary');
  const findFormWrapper = () => wrapper.find('[data-testid="board-form-wrapper"]');
  const findDeleteConfirmation = () => wrapper.find('[data-testid="delete-confirmation-message"]');
  const findInput = () => wrapper.find('#board-new-name');

  const createStore = () => {
    return new Vuex.Store({
      getters: {
        isIssueBoard: () => false,
        isEpicBoard: () => true,
        isGroupBoard: () => true,
        isProjectBoard: () => false,
      },
    });
  };

  const store = createStore();

  const createComponent = (props) => {
    wrapper = shallowMount(BoardForm, {
      propsData: { ...defaultProps, ...props },
      provide: {
        rootPath: 'root',
      },
      mocks: {
        $apollo: {
          mutate,
        },
      },
      attachTo: document.body,
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mutate = null;
  });

  describe('when creating a new epic board', () => {
    describe('on non-scoped-board', () => {
      beforeEach(() => {
        createComponent({ canAdminBoard: true, currentPage: formType.new });
      });

      it('clears the form', () => {
        expect(findInput().element.value).toBe('');
      });

      it('shows a correct title about creating a board', () => {
        expect(findModal().attributes('title')).toBe('Create new board');
      });

      it('passes correct primary action text and variant', () => {
        expect(findModalActionPrimary().text).toBe('Create board');
        expect(findModalActionPrimary().attributes[0].variant).toBe('success');
      });

      it('does not render delete confirmation message', () => {
        expect(findDeleteConfirmation().exists()).toBe(false);
      });

      it('renders form wrapper', () => {
        expect(findFormWrapper().exists()).toBe(true);
      });
    });

    describe('when submitting a create event', () => {
      const fillForm = () => {
        findInput().value = 'Test name';
        findInput().trigger('input');
        findInput().trigger('keyup.enter', { metaKey: true });
      };

      beforeEach(() => {
        mutate = jest.fn().mockResolvedValue({
          data: {
            epicBoardCreate: {
              epicBoard: { id: 'gid://gitlab/Boards::EpicBoard/123', webPath: 'test-path' },
            },
          },
        });
      });

      it('does not call API if board name is empty', async () => {
        createComponent({ canAdminBoard: true, currentPage: formType.new });
        findInput().trigger('keyup.enter', { metaKey: true });

        await waitForPromises();

        expect(mutate).not.toHaveBeenCalled();
      });

      it('calls a correct GraphQL mutation and redirects to correct page from existing board', async () => {
        createComponent({ canAdminBoard: true, currentPage: formType.new });
        fillForm();

        await waitForPromises();

        expect(mutate).toHaveBeenCalledWith({
          mutation: createEpicBoardMutation,
          variables: {
            input: expect.objectContaining({
              name: 'test',
            }),
          },
        });

        await waitForPromises();
        expect(visitUrl).toHaveBeenCalledWith('test-path');
      });

      it('shows a GlAlert if GraphQL mutation fails', async () => {
        mutate = jest.fn().mockRejectedValue('Houston, we have a problem');
        createComponent({ canAdminBoard: true, currentPage: formType.new });
        jest.spyOn(wrapper.vm, 'setError').mockImplementation(() => {});
        fillForm();

        await waitForPromises();

        expect(mutate).toHaveBeenCalled();

        await waitForPromises();
        expect(visitUrl).not.toHaveBeenCalled();
        expect(wrapper.vm.setError).toHaveBeenCalled();
      });
    });
  });

  describe('when editing an epic board', () => {
    it('calls GraphQL mutation with correct parameters', async () => {
      mutate = jest.fn().mockResolvedValue({
        data: {
          epicBoardUpdate: {
            epicBoard: { id: 'gid://gitlab/Boards::EpicBoard/321', webPath: 'test-path' },
          },
        },
      });
      createComponent({ canAdminBoard: true, currentPage: formType.edit });

      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(mutate).toHaveBeenCalledWith({
        mutation: updateEpicBoardMutation,
        variables: {
          input: expect.objectContaining({
            id: `gid://gitlab/Boards::EpicBoard/${currentBoard.id}`,
          }),
        },
      });

      await waitForPromises();
      expect(visitUrl).toHaveBeenCalledWith('test-path');
    });

    it('shows a GlAlert if GraphQL mutation fails', async () => {
      mutate = jest.fn().mockRejectedValue('Houston, we have a problem');
      createComponent({ canAdminBoard: true, currentPage: formType.edit });
      jest.spyOn(wrapper.vm, 'setError').mockImplementation(() => {});
      findInput().trigger('keyup.enter', { metaKey: true });

      await waitForPromises();

      expect(mutate).toHaveBeenCalled();

      await waitForPromises();
      expect(visitUrl).not.toHaveBeenCalled();
      expect(wrapper.vm.setError).toHaveBeenCalled();
    });
  });

  describe('when deleting an epic board', () => {
    it('passes correct primary action text and variant', () => {
      createComponent({ canAdminBoard: true, currentPage: formType.delete });
      expect(findModalActionPrimary().text).toBe('Delete');
      expect(findModalActionPrimary().attributes[0].variant).toBe('danger');
    });

    it('renders delete confirmation message', () => {
      createComponent({ canAdminBoard: true, currentPage: formType.delete });
      expect(findDeleteConfirmation().exists()).toBe(true);
    });

    it('calls a correct GraphQL mutation and redirects to correct page after deleting board', async () => {
      mutate = jest.fn().mockResolvedValue({});
      createComponent({ canAdminBoard: true, currentPage: formType.delete });
      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(mutate).toHaveBeenCalledWith({
        mutation: destroyEpicBoardMutation,
        variables: {
          id: 'gid://gitlab/Boards::EpicBoard/1',
        },
      });

      await waitForPromises();
      expect(visitUrl).toHaveBeenCalledWith('root');
    });

    it('shows a GlAlert if GraphQL mutation fails', async () => {
      mutate = jest.fn().mockRejectedValue('Houston, we have a problem');
      createComponent({ canAdminBoard: true, currentPage: formType.delete });
      jest.spyOn(wrapper.vm, 'setError').mockImplementation(() => {});
      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(mutate).toHaveBeenCalled();

      await waitForPromises();
      expect(visitUrl).not.toHaveBeenCalled();
      expect(wrapper.vm.setError).toHaveBeenCalled();
    });
  });
});
