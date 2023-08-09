<script>
import { GlCard, GlTable, GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { thWidthPercent } from '~/lib/utils/table_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';
import { EMPTY_STATUS_CHECK } from '../constants';
import Actions from './actions.vue';
import Branch from './branch.vue';
import ModalCreate from './modal_create.vue';
import ModalDelete from './modal_delete.vue';
import ModalUpdate from './modal_update.vue';

export const i18n = {
  title: s__('StatusCheck|Status checks'),
  description: s__(
    'StatusCheck|Check for a status response in merge requests. %{linkStart}Learn more%{linkEnd}.',
  ),
  apiHeader: __('API'),
  branchHeader: __('Target branch'),
  actionsHeader: __('Actions'),
  emptyTableText: s__('StatusCheck|No status checks are defined yet.'),
  nameHeader: s__('StatusCheck|Service name'),
};

export default {
  components: {
    Actions,
    Branch,
    GlCard,
    GlTable,
    GlIcon,
    GlLink,
    GlSprintf,
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
      label: i18n.actionsHeader,
      thClass: 'gl-text-right',
      tdClass: 'gl-text-right',
    },
  ],
  helpUrl: helpPagePath('/user/project/merge_requests/status_checks'),
  i18n,
};
</script>

<template>
  <gl-card
    class="gl-new-card"
    header-class="gl-new-card-header"
    body-class="gl-new-card-body gl-px-0"
  >
    <template #header>
      <div class="gl-new-card-title-wrapper gl-flex-direction-column">
        <h5 class="gl-new-card-title">
          {{ $options.i18n.title }}
          <span class="gl-new-card-count">
            <gl-icon name="check-circle" class="gl-mr-2" />
            {{ statusChecks.length }}
          </span>
        </h5>
        <p class="gl-new-card-description">
          <gl-sprintf :message="$options.i18n.description">
            <template #link>
              <gl-link class="gl-font-sm" :href="$options.helpUrl" target="_blank">{{
                __('Learn more')
              }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
      </div>
      <modal-create />
    </template>

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

    <modal-delete ref="deleteModal" :status-check="statusCheckToDelete" />
    <modal-update ref="updateModal" :status-check="statusCheckToUpdate" />
  </gl-card>
</template>
