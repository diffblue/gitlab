<script>
import {
  GlButton,
  GlIcon,
  GlDropdownDivider,
  GlDropdownItem,
  GlDropdownSectionHeader,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapActions } from 'vuex';

import searchIterationQuery from 'ee/issues/list/queries/search_iterations.query.graphql';
import { getIterationPeriod } from 'ee/iterations/utils';
import { n__, s__, __, sprintf } from '~/locale';
import { TYPENAME_ITERATION } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';

import {
  IterationsPreset,
  IterationFilterType,
  ANY_ITERATION,
  CURRENT_ITERATION,
} from '../constants';

export default {
  IterationsPreset,
  components: {
    GlButton,
    GlIcon,
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
    DropdownWidget,
    TooltipOnTruncate,
  },
  inject: ['fullPath', 'isProjectBoard', 'boardType'],
  props: {
    board: {
      type: Object,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      search: '',
      iterations: [],
      selected: this.board.iteration?.id
        ? {
            ...this.board.iteration,
            id: convertToGraphQLId(TYPENAME_ITERATION, getIdFromGraphQLId(this.board.iteration.id)),
            iterationCadenceId: this.board.iterationCadence?.id,
            cadenceTitle: this.board.iterationCadence?.title,
          }
        : null,
      isEditing: false,
      isDropdownShowing: false,
    };
  },
  apollo: {
    iterations: {
      query: searchIterationQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          search: this.search,
          isProject: this.isProjectBoard,
        };
      },
      skip() {
        return !this.isEditing;
      },
      update(data) {
        return data[this.boardType]?.iterations?.nodes || [];
      },
      error() {
        this.setError({ message: this.$options.i18n.errorSearchingIterations });
      },
    },
  },
  computed: {
    anyIteration() {
      return this.selected.id === ANY_ITERATION.id && this.selected.iterationCadenceId === null;
    },
    iterationTitle() {
      if (this.selected.cadenceTitle) {
        return sprintf(s__('BoardScope|%{iterationTitle} iteration in %{iterationCadence}'), {
          iterationTitle: this.selected.title,
          iterationCadence: this.selected.cadenceTitle,
        });
      }
      return this.anyIteration ? ANY_ITERATION.title : this.selected.title;
    },
    iterationTitleClass() {
      return this.anyIteration ? 'gl-text-secondary' : 'gl-font-weight-bold';
    },
    isLoading() {
      return this.$apollo.queries.iterations.loading;
    },
    iterationsByCadence() {
      const cadences = [];
      this.iterations.forEach((iteration) => {
        if (!iteration.iterationCadence) {
          return;
        }
        const { title, durationInWeeks, id } = iteration.iterationCadence;
        const cadenceIteration = {
          key: `${iteration.iterationCadence.id}-${iteration.id}`,
          id: iteration.id,
          title: this.iterationOptionText(iteration),
          iterationCadenceId: id,
        };
        const cadence = cadences.find((cad) => cad.title === title);
        if (cadence) {
          cadence.options.push(cadenceIteration);
        } else {
          const durationText = durationInWeeks
            ? n__('Every week', 'Every %d weeks', durationInWeeks)
            : null;
          cadences.push({
            id,
            title,
            secondaryText: durationText,
            options: [
              {
                key: `${id}-${IterationFilterType.any}`,
                id: ANY_ITERATION.id,
                iterationCadenceId: id,
                title: IterationFilterType.any,
                cadenceTitle: title,
              },
              {
                key: `${id}-${IterationFilterType.current}`,
                id: CURRENT_ITERATION.id,
                iterationCadenceId: id,
                title: IterationFilterType.current,
                cadenceTitle: title,
              },
              cadenceIteration,
            ],
          });
        }
      });
      return cadences;
    },
  },
  created() {
    if (isEmpty(this.board.iteration)) {
      this.selected = ANY_ITERATION;
    }
  },
  methods: {
    ...mapActions(['setError']),
    selectIteration(iteration) {
      this.selected = iteration;
      this.toggleEdit();
      this.$emit(
        'set-iteration',
        !this.anyIteration ? iteration : { id: null, iterationCadenceId: null },
      );
    },
    toggleEdit() {
      if (!this.isEditing && !this.isDropdownShowing) {
        this.isEditing = true;
        this.showDropdown();
      } else {
        this.hideDropdown();
      }
    },
    showDropdown() {
      this.$refs.editDropdown.showDropdown();
      this.isDropdownShowing = true;
    },
    hideDropdown() {
      this.isEditing = false;
      this.isDropdownShowing = false;
    },
    setSearch(search) {
      this.search = search;
    },
    iterationOptionText(iteration) {
      return iteration.title
        ? `${iteration.title}: ${getIterationPeriod(iteration)}`
        : getIterationPeriod(iteration);
    },
    isSelected(option) {
      const isIterationSelected = this.selected && option.id && this.selected.id === option.id;
      return option.iterationCadenceId
        ? isIterationSelected && this.selected.iterationCadenceId === option.iterationCadenceId
        : isIterationSelected;
    },
  },
  i18n: {
    label: s__('BoardScope|Iteration'),
    errorSearchingIterations: s__(
      'BoardScope|An error occurred while getting iterations. Please try again.',
    ),
    searchIterations: s__('BoardScope|Search iterations'),
    selectIteration: s__('BoardScope|Select iteration'),
    edit: __('Edit'),
  },
};
</script>

<template>
  <div class="block iteration">
    <div class="title gl-mb-3">
      {{ $options.i18n.label }}
      <gl-button
        v-if="canEdit"
        category="tertiary"
        size="small"
        class="edit-link float-right"
        @click="toggleEdit"
      >
        {{ $options.i18n.edit }}
      </gl-button>
    </div>
    <div v-if="!isEditing" :class="iterationTitleClass" data-testid="selected-iteration">
      {{ iterationTitle }}
    </div>

    <dropdown-widget
      v-show="isEditing"
      ref="editDropdown"
      :select-text="$options.i18n.selectIteration"
      :search-text="$options.i18n.searchIterations"
      :preset-options="$options.IterationsPreset"
      :is-loading="isLoading"
      :selected="selected"
      :search-term="search"
      :custom-is-selected-option="isSelected"
      @hide="hideDropdown"
      @set-option="selectIteration"
      @set-search="setSearch"
    >
      <template #grouped-options>
        <template v-for="(cadence, index) in iterationsByCadence">
          <gl-dropdown-divider v-if="index !== 0" :key="index" />
          <gl-dropdown-section-header :key="cadence.id">
            <div class="gl-display-flex gl-max-w-full gl-justify-content-space-between">
              <tooltip-on-truncate
                :title="cadence.title"
                class="gl-text-truncate gl-max-w-full gl-mr-3"
              >
                {{ cadence.title }}
              </tooltip-on-truncate>
              <span
                v-if="cadence.secondaryText"
                class="gl-float-right gl-font-weight-normal gl-flex-shrink-0"
              >
                <gl-icon name="clock" class="gl-mr-2" />
                {{ cadence.secondaryText }}
              </span>
            </div>
          </gl-dropdown-section-header>
          <gl-dropdown-item
            v-for="iteration in cadence.options"
            :key="iteration.key"
            :is-checked="isSelected(iteration)"
            is-check-centered
            is-check-item
            data-testid="unselected-option"
            @click="selectIteration(iteration)"
          >
            <slot name="item" :item="iteration">
              {{ iteration.title }}
            </slot>
          </gl-dropdown-item>
        </template>
      </template>
    </dropdown-widget>
  </div>
</template>
