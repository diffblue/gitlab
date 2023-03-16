<script>
import {
  GlAvatar,
  GlAvatarLabeled,
  GlButton,
  GlCollapsibleListbox,
  GlIcon,
  GlFormGroup,
  GlFormRadio,
  GlFormRadioGroup,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import BoardAddNewColumnForm from '~/boards/components/board_add_new_column_form.vue';
import { ListType } from '~/boards/constants';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import {
  groupOptionsByIterationCadences,
  groupByIterationCadences,
  getIterationPeriod,
} from 'ee/iterations/utils';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';

export const listTypeInfo = {
  [ListType.label]: {
    listPropertyName: 'labels',
    loadingPropertyName: 'labelsLoading',
    fetchMethodName: 'fetchLabels',
    noneSelected: __('Select a label'),
    searchPlaceholder: __('Search labels'),
  },
  [ListType.assignee]: {
    listPropertyName: 'assignees',
    loadingPropertyName: 'assigneesLoading',
    fetchMethodName: 'fetchAssignees',
    noneSelected: __('Select an assignee'),
    searchPlaceholder: __('Search assignees'),
  },
  [ListType.milestone]: {
    listPropertyName: 'milestones',
    loadingPropertyName: 'milestonesLoading',
    fetchMethodName: 'fetchMilestones',
    noneSelected: __('Select a milestone'),
    searchPlaceholder: __('Search milestones'),
  },
  [ListType.iteration]: {
    listPropertyName: 'iterations',
    loadingPropertyName: 'iterationsLoading',
    fetchMethodName: 'fetchIterations',
    noneSelected: __('Select an iteration'),
    searchPlaceholder: __('Search iterations'),
  },
};

export default {
  i18n: {
    value: __('Value'),
    noResults: __('No matching results'),
  },
  components: {
    BoardAddNewColumnForm,
    GlAvatar,
    GlAvatarLabeled,
    GlButton,
    GlCollapsibleListbox,
    GlIcon,
    GlFormGroup,
    GlFormRadio,
    GlFormRadioGroup,
    IterationTitle,
  },
  directives: {
    GlTooltip,
  },
  inject: [
    'scopedLabelsAvailable',
    'milestoneListsAvailable',
    'assigneeListsAvailable',
    'iterationListsAvailable',
    'isEpicBoard',
  ],
  data() {
    return {
      selectedId: null,
      selectedItem: null,
      columnType: ListType.label,
      selectedIdValid: true,
    };
  },
  computed: {
    ...mapState([
      'labels',
      'labelsLoading',
      'milestones',
      'milestonesLoading',
      'iterations',
      'iterationsLoading',
      'assignees',
      'assigneesLoading',
    ]),
    ...mapGetters(['getListByTypeId']),

    info() {
      return listTypeInfo[this.columnType] || {};
    },

    iterationCadences() {
      return groupByIterationCadences(this.items);
    },

    items() {
      return (
        this[this.info.listPropertyName].map((i) => ({
          ...i,
          text: i.title,
          value: i.id,
        })) || []
      );
    },

    listboxItems() {
      return this.iterationTypeSelected ? groupOptionsByIterationCadences(this.items) : this.items;
    },

    hasItems() {
      return this.items.length > 0;
    },

    labelTypeSelected() {
      return this.columnType === ListType.label;
    },
    assigneeTypeSelected() {
      return this.columnType === ListType.assignee;
    },
    milestoneTypeSelected() {
      return this.columnType === ListType.milestone;
    },
    iterationTypeSelected() {
      return this.columnType === ListType.iteration;
    },

    hasLabelSelection() {
      return this.labelTypeSelected && this.selectedItem;
    },
    hasMilestoneSelection() {
      return this.milestoneTypeSelected && this.selectedItem;
    },
    hasIterationSelection() {
      return this.iterationTypeSelected && this.selectedItem;
    },
    hasAssigneeSelection() {
      return this.assigneeTypeSelected && this.selectedItem;
    },

    columnForSelected() {
      if (!this.columnType || !this.selectedId) {
        return false;
      }

      const key = `${this.columnType}Id`;
      return this.getListByTypeId({
        [key]: this.selectedId,
      });
    },

    loading() {
      return this[this.info.loadingPropertyName];
    },

    columnTypes() {
      const types = [{ value: ListType.label, text: __('Label') }];

      if (this.assigneeListsAvailable) {
        types.push({ value: ListType.assignee, text: __('Assignee') });
      }

      if (this.milestoneListsAvailable) {
        types.push({ value: ListType.milestone, text: __('Milestone') });
      }

      if (this.iterationListsAvailable) {
        types.push({ value: ListType.iteration, text: __('Iteration') });
      }

      return types;
    },

    searchLabel() {
      return this.showListTypeSelector ? this.$options.i18n.value : null;
    },

    showListTypeSelector() {
      return !this.isEpicBoard && this.columnTypes.length > 1;
    },
  },
  watch: {
    selectedId(val) {
      if (val) {
        this.selectedIdValid = true;
      }
    },
  },
  created() {
    this.filterItems();
  },
  methods: {
    ...mapActions([
      'createList',
      'fetchLabels',
      'highlightList',
      'setAddColumnFormVisibility',
      'fetchAssignees',
      'fetchIterations',
      'fetchMilestones',
    ]),
    addList() {
      if (!this.selectedItem) {
        this.selectedIdValid = false;
        return;
      }

      this.setAddColumnFormVisibility(false);

      if (this.columnForSelected) {
        const listId = this.columnForSelected.id;
        this.highlightList(listId);
        return;
      }

      // eslint-disable-next-line @gitlab/require-i18n-strings
      this.createList({ [`${this.columnType}Id`]: this.selectedId });
    },

    filterItems(searchTerm) {
      this[this.info.fetchMethodName](searchTerm);
    },

    showScopedLabels(label) {
      return this.scopedLabelsAvailable && isScopedLabel(label);
    },

    setColumnType(type) {
      this.columnType = type;
      this.selectedId = null;
      this.setSelectedItem(null);
      this.filterItems();
    },

    setSelectedItem(selectedId) {
      this.selectedId = selectedId;

      const item = this.items.find(({ id }) => id === selectedId);
      if (!selectedId || !item) {
        this.selectedItem = null;
      } else {
        this.selectedItem = { ...item };
      }
    },
    onHide() {
      this.searchValue = '';
      this.$emit('filter-items', '');
      this.$emit('hide');
    },

    getIterationPeriod,
  },
};
</script>

<template>
  <board-add-new-column-form
    :search-label="searchLabel"
    :selected-id-valid="selectedIdValid"
    @filter-items="filterItems"
    @add-list="addList"
  >
    <template #select-list-type>
      <gl-form-group
        v-if="showListTypeSelector"
        :description="$options.i18n.scopeDescription"
        class="gl-px-5 gl-py-0 gl-mb-3"
        label-for="list-type"
      >
        <gl-form-radio-group v-model="columnType">
          <gl-form-radio
            v-for="{ text, value } in columnTypes"
            :key="value"
            :value="value"
            class="gl-mb-0 gl-align-self-center"
            @change="setColumnType"
          >
            {{ text }}
          </gl-form-radio>
        </gl-form-radio-group>
      </gl-form-group>
    </template>

    <template #dropdown>
      <gl-collapsible-listbox
        class="gl-mb-3 gl-max-w-full"
        :items="listboxItems"
        searchable
        :search-placeholder="info.searchPlaceholder"
        :searching="loading"
        :selected="selectedId"
        :no-results-text="$options.i18n.noResults"
        @select="setSelectedItem"
        @search="filterItems"
        @hidden="onHide"
      >
        <template #toggle>
          <gl-button
            class="gl-max-w-full gl-display-flex gl-align-items-center gl-text-truncate"
            :class="{ 'gl-inset-border-1-red-400!': !selectedIdValid }"
            button-text-classes="gl-display-flex"
          >
            <template v-if="hasLabelSelection">
              <span
                class="dropdown-label-box gl-top-0 gl-flex-shrink-0"
                :style="{
                  backgroundColor: selectedItem.color,
                }"
              ></span>
              <div class="gl-text-truncate">{{ selectedItem.title }}</div>
            </template>

            <template v-else-if="hasMilestoneSelection">
              <gl-icon class="gl-flex-shrink-0" name="clock" />
              <span class="gl-text-truncate">{{ selectedItem.title }}</span>
            </template>

            <template v-else-if="hasIterationSelection">
              <gl-icon class="gl-flex-shrink-0" name="iteration" />
              <span class="gl-text-truncate">{{
                selectedItem.title || getIterationPeriod(selectedItem)
              }}</span>
            </template>

            <template v-else-if="hasAssigneeSelection">
              <gl-avatar
                class="gl-mr-2 gl-flex-shrink-0"
                :size="16"
                :src="selectedItem.avatarUrl"
              />
              <div class="gl-text-truncate">
                <b class="gl-mr-2">{{ selectedItem.name }}</b>
                <span class="gl-text-gray-700">@{{ selectedItem.username }}</span>
              </div>
            </template>

            <template v-else>{{ info.noneSelected }}</template>
            <gl-icon class="dropdown-chevron gl-ml-2" name="chevron-down" />
          </gl-button>
        </template>

        <template #group-label="{ group }">
          {{ group.text }}
        </template>

        <template #list-item="{ item }">
          <label class="gl-display-flex gl-font-weight-normal gl-overflow-break-word gl-mb-0">
            <span
              v-if="labelTypeSelected"
              class="dropdown-label-box gl-top-0 gl-flex-shrink-0"
              :style="{
                backgroundColor: item.color,
              }"
            ></span>

            <gl-avatar-labeled
              v-if="assigneeTypeSelected"
              class="gl-display-flex gl-align-items-center"
              :size="32"
              :label="item.name"
              :sub-label="`@${item.username}`"
              :src="item.avatarUrl"
            />
            <div
              v-else-if="iterationTypeSelected"
              class="gl-display-inline-block"
              data-testid="new-column-iteration-item"
            >
              {{ item.text }}
              <iteration-title v-if="item.title" :title="item.title" />
            </div>
            <div v-else class="gl-display-inline-block">
              {{ item.text }}
            </div>
          </label>
        </template>
      </gl-collapsible-listbox>
    </template>
  </board-add-new-column-form>
</template>
