<script>
import {
  GlFormGroup,
  GlDropdown,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlDropdownDivider,
  GlSkeletonLoader,
  GlSearchBoxByType,
  GlDropdownText,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { debounce } from 'lodash';
import Tracking from '~/tracking';
import { s__ } from '~/locale';
import { groupByIterationCadences, getIterationPeriod } from 'ee/iterations/utils';
import {
  i18n,
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  TRACKING_CATEGORY_SHOW,
  I18N_WORK_ITEM_FETCH_ITERATIONS_ERROR,
} from '~/work_items/constants';
import { STATUS_OPEN } from '~/issues/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import projectIterationsQuery from 'ee/work_items/graphql/project_iterations.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemIterationSubscription from 'ee/work_items/graphql/work_item_iteration.subscription.graphql';

const noIterationId = 'no-iteration-id';

export default {
  i18n: {
    ITERATION: s__('WorkItem|Iteration'),
    NONE: s__('WorkItem|None'),
    ITERATION_PLACEHOLDER: s__('WorkItem|Add to iteration'),
    NO_MATCHING_RESULTS: s__('WorkItem|No matching results'),
    NO_ITERATION: s__('WorkItem|No iteration'),
  },
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlDropdownDivider,
    GlSkeletonLoader,
    GlSearchBoxByType,
    GlDropdownText,
  },
  mixins: [Tracking.mixin()],
  inject: ['hasIterationsFeature'],
  props: {
    iteration: {
      type: Object,
      required: false,
      default: null,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
      isFocused: false,
      shouldFetch: false,
      selectedIterationId: null,
      updateInProgress: false,
      localIteration: this.iteration,
    };
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_iteration',
        property: `type_${this.workItemType}`,
      };
    },
    iterationPeriod() {
      return this.localIteration?.period || getIterationPeriod(this.localIteration);
    },
    iterationTitle() {
      return this.localIteration?.title || this.iterationPeriod;
    },
    groupedIterationCadences() {
      return !this.isLoadingIterations && this.iterations
        ? groupByIterationCadences(this.iterations)
        : [];
    },
    isLoadingIterations() {
      return this.$apollo.queries.iterations.loading;
    },
    dropdownClasses() {
      return {
        'gl-text-gray-500!': this.canUpdate && this.isNoIteration,
        'is-not-focused': !this.isFocused,
      };
    },
    doesNotMeetCriteriaToUpdate() {
      return this.selectedIterationId === this.iteration?.id || !this.selectedIterationId;
    },
    noIterationDefaultText() {
      return this.canUpdate ? this.$options.i18n.ITERATION_PLACEHOLDER : this.$options.i18n.NONE;
    },
    dropdownText() {
      return this.localIteration?.id && this.localIteration?.id !== noIterationId
        ? this.iterationTitle
        : this.noIterationDefaultText;
    },
    isNoIteration() {
      return !this.localIteration?.id;
    },
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.workspace.workItems.nodes[0];
      },
      skip() {
        return !this.queryVariables.iid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
      subscribeToMore: {
        document: workItemIterationSubscription,
        variables() {
          return {
            issuableId: this.workItemId,
          };
        },
      },
    },
    iterations: {
      query: projectIterationsQuery,
      variables() {
        const search = this.searchTerm ? `"${this.searchTerm}"` : '';
        return {
          fullPath: this.fullPath,
          title: search,
          state: STATUS_OPEN,
        };
      },
      update(data) {
        return data.workspace?.attributes?.nodes || [];
      },
      skip() {
        return !this.shouldFetch;
      },
      error() {
        this.$emit('error', I18N_WORK_ITEM_FETCH_ITERATIONS_ERROR);
      },
    },
  },
  watch: {
    iteration: {
      handler(newVal) {
        this.localIteration = newVal;
      },
      deep: true,
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    isIterationChecked(iteration) {
      return this.selectedIterationId
        ? this.selectedIterationId === iteration.id
        : this.localIteration?.id === iteration.id;
    },
    setSearchKey(value) {
      this.searchTerm = value;
    },
    onDropdownShown() {
      this.$refs.search.focusInput();
      this.shouldFetch = true;
      this.isFocused = true;
    },
    onDropdownHide() {
      this.updateWorkItemIteration();
      this.isFocused = false;
      this.searchTerm = '';
      this.selectedIterationId = null;
    },
    async updateWorkItemIteration() {
      if (this.doesNotMeetCriteriaToUpdate) {
        return;
      }
      this.updateInProgress = true;
      try {
        const {
          data: {
            workItemUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              iterationWidget: {
                iterationId:
                  this.selectedIterationId === noIterationId ? null : this.selectedIterationId,
              },
            },
          },
        });
        this.track('updated_iteration');
        if (errors.length > 0) {
          throw new Error(errors.join('\n'));
        }
      } catch (error) {
        const msg = sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType);
        this.$emit('error', msg);
        Sentry.captureException(error);
      }
      this.updateInProgress = false;
    },
    updateLocalIteration(iteration) {
      this.localIteration = iteration;
      this.selectedIterationId = iteration.id;
    },
  },
};
</script>

<template>
  <gl-form-group
    v-if="hasIterationsFeature"
    class="work-item-dropdown"
    :label="$options.i18n.ITERATION"
    label-class="gl-pb-0! gl-overflow-wrap-break gl-mt-3"
    label-cols="3"
    label-cols-lg="2"
  >
    <span
      v-if="!canUpdate"
      class="gl-text-secondary gl-ml-4 gl-mt-3 gl-display-inline-block gl-line-height-normal"
      data-testid="disabled-text"
    >
      {{ dropdownText }}
    </span>
    <gl-dropdown
      v-else
      :toggle-class="dropdownClasses"
      :text="dropdownText"
      :loading="updateInProgress"
      :disabled="!canUpdate"
      @shown="onDropdownShown"
      @hide="onDropdownHide"
    >
      <template #header>
        <gl-search-box-by-type ref="search" :value="searchTerm" @input="debouncedSearchKeyUpdate" />
      </template>
      <gl-dropdown-item
        data-testid="no-iteration"
        is-check-item
        :is-checked="isNoIteration"
        @click="updateLocalIteration({ id: 'no-iteration-id' })"
      >
        {{ $options.i18n.NO_ITERATION }}
      </gl-dropdown-item>
      <gl-dropdown-divider />
      <gl-dropdown-text v-if="isLoadingIterations">
        <gl-skeleton-loader :height="90">
          <rect width="380" height="10" x="10" y="15" rx="4" />
          <rect width="280" height="10" x="10" y="30" rx="4" />
          <rect width="380" height="10" x="10" y="50" rx="4" />
          <rect width="280" height="10" x="10" y="65" rx="4" />
        </gl-skeleton-loader>
      </gl-dropdown-text>

      <template v-else-if="groupedIterationCadences.length">
        <template v-for="(cadence, index) in groupedIterationCadences">
          <gl-dropdown-section-header :key="`header-${cadence.id}`">
            {{ cadence.title }}
          </gl-dropdown-section-header>
          <gl-dropdown-item
            v-for="currentIteration in cadence.iterations"
            :key="currentIteration.id"
            is-check-item
            :is-checked="isIterationChecked(currentIteration)"
            @click="updateLocalIteration(currentIteration)"
          >
            <span>{{ currentIteration.period }}</span>
            <span>{{ currentIteration.title }}</span>
          </gl-dropdown-item>
          <gl-dropdown-divider
            v-if="index !== groupedIterationCadences.length - 1"
            :key="`divider-${cadence.id}`"
          />
        </template>
      </template>
      <gl-dropdown-text v-else>{{ $options.i18n.NO_MATCHING_RESULTS }}</gl-dropdown-text>
    </gl-dropdown>
  </gl-form-group>
</template>
