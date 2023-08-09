import { GlCard, GlTable } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Actions from 'ee/status_checks/components/actions.vue';
import Branch from 'ee/status_checks/components/branch.vue';
import ModalCreate from 'ee/status_checks/components/modal_create.vue';
import ModalDelete from 'ee/status_checks/components/modal_delete.vue';
import ModalUpdate from 'ee/status_checks/components/modal_update.vue';
import StatusChecks, { i18n } from 'ee/status_checks/components/status_checks.vue';
import createStore from 'ee/status_checks/store';
import { SET_STATUS_CHECKS } from 'ee/status_checks/store/mutation_types';
import { stubComponent } from 'helpers/stub_component';

Vue.use(Vuex);

const statusChecks = [
  { name: 'Foo', externalUrl: 'http://foo.com/api', protectedBranches: [] },
  { name: 'Bar', externalUrl: 'http://bar.com/api', protectedBranches: [{ name: 'main' }] },
];

describe('Status checks', () => {
  let store;
  let wrapper;

  const createWrapper = (mountFn = mount, { stubs = {} } = {}) => {
    store = createStore();
    wrapper = mountFn(StatusChecks, {
      store,
      stubs,
    });
  };

  const findCreateModal = () => wrapper.findComponent(ModalCreate);
  const findDeleteModal = () => wrapper.findComponent(ModalDelete);
  const findUpdateModal = () => wrapper.findComponent(ModalUpdate);
  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaders = () => findTable().find('thead').find('tr').findAll('th');
  const findBranch = (trIdx) => wrapper.findAllComponents(Branch).at(trIdx);
  const findActions = (trIdx) => wrapper.findAllComponents(Actions).at(trIdx);
  const findCell = (trIdx, tdIdx) => {
    return findTable().find('tbody').findAll('tr').at(trIdx).findAll('td').at(tdIdx);
  };

  describe('Initially', () => {
    it('renders the table', () => {
      createWrapper(shallowMount);

      expect(findTable().exists()).toBe(true);
    });

    it('renders the empty state when no status checks exist', () => {
      createWrapper();

      expect(findCell(0, 0).text()).toBe(i18n.emptyTableText);
    });

    it('creates the create modal', () => {
      createWrapper(shallowMount, { stubs: { GlCard } });

      expect(findCreateModal().exists()).toBe(true);
    });

    it('creates the update modal', () => {
      createWrapper(shallowMount, { stubs: { GlCard } });

      expect(findUpdateModal().exists()).toBe(true);
    });
  });

  describe('Table', () => {
    beforeEach(() => {
      createWrapper();
      store.commit(SET_STATUS_CHECKS, statusChecks);
    });

    it('renders the headers', () => {
      expect(findHeaders()).toHaveLength(4);
      expect(findHeaders().at(0).text()).toBe(i18n.nameHeader);
      expect(findHeaders().at(1).text()).toBe(i18n.apiHeader);
      expect(findHeaders().at(2).text()).toBe(i18n.branchHeader);
      expect(findHeaders().at(3).text()).toBe(i18n.actionsHeader);
    });

    describe.each(statusChecks)('status check %#', (statusCheck) => {
      const index = statusChecks.indexOf(statusCheck);

      it('renders the name', () => {
        expect(findCell(index, 0).text()).toBe(statusCheck.name);
      });

      it('renders the URL', () => {
        expect(findCell(index, 1).text()).toBe(statusCheck.externalUrl);
      });

      it('renders the branch', () => {
        expect(findBranch(index, 1).props('branches')).toBe(statusCheck.protectedBranches);
      });

      it('renders the actions', () => {
        expect(findActions(index, 1).props('statusCheck')).toStrictEqual(statusCheck);
      });
    });
  });

  describe('Delete modal filling', () => {
    beforeEach(() => {
      createWrapper();
      store.commit(SET_STATUS_CHECKS, statusChecks);
    });

    it('opens the delete modal with the correct status check when a remove button is clicked', async () => {
      const statusCheck = findActions(0, 1).props('statusCheck');

      await findActions(0, 1).vm.$emit('open-delete-modal', statusCheck);

      expect(findDeleteModal().props('statusCheck')).toStrictEqual(statusCheck);
    });

    it('updates the status check prop for the delete modal when another remove button is clicked', async () => {
      const statusCheck = findActions(1, 1).props('statusCheck');

      await findActions(0, 1).vm.$emit('open-delete-modal', findActions(0, 1).props('statusCheck'));
      await findActions(1, 1).vm.$emit('open-delete-modal', statusCheck);

      expect(findDeleteModal().props('statusCheck')).toStrictEqual(statusCheck);
    });

    it('shows modal when clicked', async () => {
      const mockDeleteModalShow = jest.fn();

      createWrapper(mount, {
        stubs: {
          ModalDelete: stubComponent(ModalDelete, {
            props: {
              modalId: 'some-modal-id',
            },
            methods: {
              show: mockDeleteModalShow,
            },
          }),
        },
      });
      store.commit(SET_STATUS_CHECKS, statusChecks);

      await nextTick();
      await findActions(0, 1).vm.$emit('open-delete-modal');

      expect(mockDeleteModalShow).toHaveBeenCalled();
    });
  });

  describe('Update modal filling', () => {
    beforeEach(() => {
      createWrapper(mount, { stubs: { StatusCheckForm: true } });
      store.commit(SET_STATUS_CHECKS, statusChecks);
    });

    it('opens the update modal with the correct status check when an edit button is clicked', async () => {
      const statusCheck = findActions(0, 1).props('statusCheck');

      await findActions(0, 1).vm.$emit('open-update-modal', statusCheck);

      expect(findUpdateModal().props('statusCheck')).toStrictEqual(statusCheck);
    });

    it('updates the status check prop for the update modal when another edit button is clicked', async () => {
      const statusCheck = findActions(1, 1).props('statusCheck');

      await findActions(0, 1).vm.$emit(
        'update-status-to-check',
        findActions(0, 1).props('statusCheck'),
      );
      await findActions(1, 1).vm.$emit('open-update-modal', statusCheck);

      expect(findUpdateModal().props('statusCheck')).toStrictEqual(statusCheck);
    });

    it('shows modal when clicked', async () => {
      const mockUpdateModalShow = jest.fn();
      createWrapper(mount, {
        stubs: {
          ModalUpdate: stubComponent(ModalUpdate, {
            props: {
              modalId: 'modal-update',
            },
            methods: {
              show: mockUpdateModalShow,
            },
          }),
        },
      });
      store.commit(SET_STATUS_CHECKS, statusChecks);

      await nextTick();
      await findActions(0, 1).vm.$emit('open-update-modal');

      expect(mockUpdateModalShow).toHaveBeenCalled();
    });
  });
});
