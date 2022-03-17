<script>
import {
  GlAlert,
  GlBadge,
  GlDropdown,
  GlDropdownItem,
  GlEmptyState,
  GlIcon,
  GlLoadingIcon,
  GlModal,
  GlSafeHtmlDirective,
} from '@gitlab/ui';
import BurnCharts from 'ee/burndown_chart/components/burn_charts.vue';
import { TYPE_ITERATION } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { Namespace } from '../constants';
import deleteIteration from '../queries/destroy_iteration.mutation.graphql';
import query from '../queries/iteration.query.graphql';
import { getIterationPeriod } from '../utils';
import IterationForm from './iteration_form_without_vue_router.vue';
import IterationReportTabs from './iteration_report_tabs.vue';
import IterationTitle from './iteration_title.vue';

const iterationStates = {
  closed: 'closed',
  upcoming: 'upcoming',
  expired: 'expired',
};

const page = {
  view: 'viewIteration',
  edit: 'editIteration',
};

export default {
  components: {
    BurnCharts,
    GlAlert,
    GlBadge,
    GlIcon,
    GlDropdown,
    GlDropdownItem,
    GlEmptyState,
    GlLoadingIcon,
    IterationForm,
    IterationReportTabs,
    IterationTitle,
    GlModal,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  apollo: {
    iteration: {
      query,
      variables() {
        return {
          fullPath: this.fullPath,
          id: convertToGraphQLId(TYPE_ITERATION, this.iterationId),
          isGroup: this.namespaceType === Namespace.Group,
        };
      },
      update(data) {
        return data[this.namespaceType]?.iterations?.nodes[0] || {};
      },
      error(err) {
        this.error = err.message;
      },
    },
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['fullPath'],
  props: {
    hasScopedLabelsFeature: {
      type: Boolean,
      required: false,
      default: false,
    },
    iterationId: {
      type: String,
      required: false,
      default: undefined,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    initiallyEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    labelsFetchPath: {
      type: String,
      required: false,
      default: '',
    },
    namespaceType: {
      type: String,
      required: false,
      default: Namespace.Group,
      validator: (value) => Object.values(Namespace).includes(value),
    },
    previewMarkdownPath: {
      type: String,
      required: false,
      default: '',
    },
    svgPath: {
      type: String,
      required: false,
      default: '',
    },
    iterationsListPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isEditing: this.initiallyEditing,
      error: '',
      iteration: {},
    };
  },
  computed: {
    canEditIteration() {
      return this.canEdit && this.namespaceType === Namespace.Group;
    },
    loading() {
      return this.$apollo.queries.iteration.loading;
    },
    showEmptyState() {
      return !this.loading && this.iteration && !this.iteration.startDate;
    },
    status() {
      switch (this.iteration.state) {
        case iterationStates.closed:
          return {
            text: __('Closed'),
            variant: 'danger',
          };
        case iterationStates.expired:
          return { text: __('Past due'), variant: 'warning' };
        case iterationStates.upcoming:
          return { text: __('Upcoming'), variant: 'neutral' };
        default:
          return { text: __('Open'), variant: 'success' };
      }
    },
    iterationPeriod() {
      return getIterationPeriod(this.iteration);
    },
  },
  mounted() {
    this.boundOnPopState = this.onPopState.bind(this);
    window.addEventListener('popstate', this.boundOnPopState);
  },
  beforeDestroy() {
    window.removeEventListener('popstate', this.boundOnPopState);
  },
  methods: {
    onPopState(e) {
      if (e.state?.prev === page.view) {
        this.isEditing = true;
      } else if (e.state?.prev === page.edit) {
        this.isEditing = false;
      } else {
        this.isEditing = this.initiallyEditing;
      }
    },
    formatDate(date) {
      return formatDate(date, 'mmm d, yyyy', true);
    },
    loadEditPage() {
      this.isEditing = true;
      const newUrl = window.location.pathname.replace(/(\/edit)?\/?$/, '/edit');
      window.history.pushState({ prev: page.view }, null, newUrl);
    },
    loadReportPage() {
      this.isEditing = false;
      const newUrl = window.location.pathname.replace(/\/edit$/, '');
      window.history.pushState({ prev: page.edit }, null, newUrl);
    },
    showModal() {
      this.$refs.modal.show();
    },
    focusMenu() {
      this.$refs.menu.$el.focus();
    },
    deleteIteration() {
      this.$apollo
        .mutate({
          mutation: deleteIteration,
          variables: {
            id: convertToGraphQLId(TYPE_ITERATION, this.iterationId),
          },
        })
        .then(({ data: { iterationDelete } }) => {
          if (iterationDelete.errors?.length) {
            throw iterationDelete.errors[0];
          }

          this.isEditing = false;

          this.$toast.show(s__('Iterations|The iteration has been deleted.'));
          visitUrl(this.iterationsListPath);
        })
        .catch((err) => {
          this.error = err;
        });
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="error = ''">
      {{ error }}
    </gl-alert>
    <gl-loading-icon v-else-if="loading" class="gl-py-5" size="lg" />
    <gl-empty-state
      v-else-if="showEmptyState"
      :title="__('Could not find iteration')"
      :compact="false"
    />
    <iteration-form
      v-else-if="isEditing"
      :group-path="fullPath"
      :preview-markdown-path="previewMarkdownPath"
      :is-editing="true"
      :iteration="iteration"
      @updated="loadReportPage"
      @cancel="loadReportPage"
    />
    <template v-else>
      <div
        ref="topbar"
        class="gl-display-flex gl-justify-items-center gl-align-items-center gl-py-3 gl-border-1 gl-border-b-solid gl-border-gray-100"
      >
        <gl-badge :variant="status.variant">
          {{ status.text }}
        </gl-badge>
        <span class="gl-ml-4">{{ iterationPeriod }}</span>
        <gl-dropdown
          v-if="canEditIteration"
          ref="menu"
          data-testid="actions-dropdown"
          variant="default"
          toggle-class="gl-text-decoration-none gl-border-0! gl-shadow-none!"
          class="gl-ml-auto gl-text-secondary"
          right
          no-caret
        >
          <template #button-content>
            <gl-icon name="ellipsis_v" /><span class="gl-sr-only">{{ __('Actions') }}</span>
          </template>
          <gl-dropdown-item @click="loadEditPage">{{ __('Edit') }}</gl-dropdown-item>
          <gl-dropdown-item data-testid="delete-iteration" @click="showModal">
            {{ __('Delete') }}
          </gl-dropdown-item>
        </gl-dropdown>
        <gl-modal
          ref="modal"
          :modal-id="`${iterationId}-delete-modal`"
          :title="s__('Iterations|Delete iteration?')"
          :ok-title="__('Delete')"
          ok-variant="danger"
          @hidden="focusMenu"
          @ok="deleteIteration"
        >
          {{
            s__(
              'Iterations|This will remove the iteration from any issues that are assigned to it.',
            )
          }}
        </gl-modal>
      </div>
      <div ref="heading">
        <h3 class="page-title gl-mb-1" data-testid="iteration-period">{{ iterationPeriod }}</h3>
        <iteration-title v-if="iteration.title" :title="iteration.title" class="text-secondary" />
      </div>
      <div
        ref="description"
        v-safe-html:[$options.safeHtmlConfig]="iteration.descriptionHtml"
      ></div>
      <burn-charts
        :start-date="iteration.startDate"
        :due-date="iteration.dueDate"
        :iteration-id="iteration.id"
        :iteration-state="iteration.state"
        :full-path="fullPath"
        :namespace-type="namespaceType"
      />
      <iteration-report-tabs
        :full-path="fullPath"
        :has-scoped-labels-feature="hasScopedLabelsFeature"
        :iteration-id="iteration.id"
        :labels-fetch-path="labelsFetchPath"
        :namespace-type="namespaceType"
        :svg-path="svgPath"
      />
    </template>
  </div>
</template>
