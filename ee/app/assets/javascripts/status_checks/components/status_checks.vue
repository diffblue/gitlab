<script>
import { GlTable } from '@gitlab/ui';
import { mapState } from 'vuex';
import { thWidthPercent } from '~/lib/utils/table_utility';
import { __, s__ } from '~/locale';
import { EMPTY_STATUS_CHECK } from '../constants';
import Actions from './actions.vue';
import Branch from './branch.vue';
import ModalCreate from './modal_create.vue';
import ModalDelete from './modal_delete.vue';
import ModalUpdate from './modal_update.vue';

export const i18n = {
  apiHeader: __('API'),
  branchHeader: __('Target branch'),
  emptyTableText: s__('StatusCheck|No status checks are defined yet.'),
  nameHeader: s__('StatusCheck|Service name'),
};

export default {
  components: {
    Actions,
    Branch,
    GlTable,
    ModalCreate,
    ModalDelete,
    ModalUpdate,
  },
  data() {
    return {
      statusCheckToDelete: EMPTY_STATUS_CHECK,
      statusCheckToUpdate: EMPTY_STATUS_CHECK,
    };
  },
  computed: {
    ...mapState(['statusChecks']),
  },
  methods: {
    openDeleteModal(statusCheck) {
      this.statusCheckToDelete = statusCheck;
      this.$refs.deleteModal.show();
    },
    openUpdateModal(statusCheck) {
      this.statusCheckToUpdate = statusCheck;
      this.$refs.updateModal.show();
    },
  },
  fields: [
    {
      key: 'name',
      label: i18n.nameHeader,
      thClass: thWidthPercent(20),
    },
    {
      key: 'externalUrl',
      label: i18n.apiHeader,
      thClass: thWidthPercent(40),
    },
    {
      key: 'protectedBranches',
      label: i18n.branchHeader,
      thClass: thWidthPercent(20),
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-text-right',
    },
  ],
  i18n,
};
</script>

<template>
  <div>
    <gl-table
      :items="statusChecks"
      :fields="$options.fields"
      primary-key="id"
      :empty-text="$options.i18n.emptyTableText"
      show-empty
      stacked="md"
      data-testid="status-checks-table"
    >
      <template #cell(protectedBranches)="{ item }">
        <branch :branches="item.protectedBranches" />
      </template>
      <template #cell(actions)="{ item }">
        <actions
          :status-check="item"
          @open-delete-modal="openDeleteModal"
          @open-update-modal="openUpdateModal"
        />
      </template>
    </gl-table>

    <modal-create />
    <modal-delete ref="deleteModal" :status-check="statusCheckToDelete" />
    <modal-update ref="updateModal" :status-check="statusCheckToUpdate" />
  </div>
</template>
