<script>
import { GlButton } from '@gitlab/ui';
import { debounce } from 'lodash';
import { mapActions } from 'vuex';
import { __, s__, sprintf } from '~/locale';
import LabelItem from '~/sidebar/components/labels/labels_select_widget/label_item.vue';
import searchGroupLabels from '~/sidebar/components/labels/labels_select_widget/graphql/group_labels.query.graphql';
import searchProjectLabels from '~/sidebar/components/labels/labels_select_widget/graphql/project_labels.query.graphql';
import DropdownValue from '~/sidebar/components/labels/labels_select_widget/dropdown_value.vue';
import DropdownContentsCreateView from '~/sidebar/components/labels/labels_select_widget/dropdown_contents_create_view.vue';
import DropdownHeader from '~/sidebar/components/labels/labels_select_widget/dropdown_header.vue';
import DropdownFooter from '~/sidebar/components/labels/labels_select_widget/dropdown_footer.vue';
import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';

export default {
  components: {
    DropdownWidget,
    GlButton,
    LabelItem,
    DropdownValue,
    DropdownContentsCreateView,
    DropdownHeader,
    DropdownFooter,
  },
  inject: ['fullPath', 'boardType', 'isProjectBoard'],
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
      labels: [],
      selected: this.board.labels,
      isEditing: false,
      showDropdownContentsCreateView: false,
    };
  },
  apollo: {
    labels: {
      query() {
        return this.isProjectBoard ? searchProjectLabels : searchGroupLabels;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          searchTerm: this.search,
          first: 20,
        };
      },
      skip() {
        return !this.isEditing;
      },
      update(data) {
        return data.workspace?.labels?.nodes;
      },
      error() {
        this.setError({ message: this.$options.i18n.errorSearchingLabels });
      },
    },
  },
  computed: {
    isLabelsEmpty() {
      return this.selected.length === 0;
    },
    selectedLabelsIds() {
      return this.selected.map((label) => label.id);
    },
    isLoading() {
      return this.$apollo.queries.labels.loading;
    },
    selectText() {
      if (!this.selected.length) {
        return this.$options.i18n.selectLabel;
      } else if (this.selected.length > 1) {
        return sprintf(s__('LabelSelect|%{firstLabelName} +%{remainingLabelCount} more'), {
          firstLabelName: this.selected[0].title,
          remainingLabelCount: this.selected.length - 1,
        });
      }
      return this.selected[0].title;
    },
    footerCreateLabelTitle() {
      return sprintf(__('Create %{workspace} label'), {
        workspace: this.boardType,
      });
    },
    footerManageLabelTitle() {
      return sprintf(__('Manage %{workspace} labels'), {
        workspace: this.boardType,
      });
    },
    labelType() {
      return this.boardType;
    },
  },
  methods: {
    ...mapActions(['setError']),
    isLabelSelected(label) {
      return this.selectedLabelsIds.includes(label.id);
    },
    selectLabel(label) {
      let labels = [];
      if (this.isLabelSelected(label)) {
        labels = this.selected.filter(({ id }) => id !== label.id);
      } else {
        labels = [...this.selected, label];
      }
      this.selected = labels;
      this.$emit('set-labels', labels);
    },
    onLabelRemove(labelId) {
      const labels = this.selected.filter(({ id }) => id !== labelId);
      this.selected = labels;
      this.$emit('set-labels', labels);
    },
    toggleEdit() {
      if (!this.isEditing) {
        this.showDropdown();
      } else {
        this.hideDropdown();
      }
    },
    showDropdown() {
      this.isEditing = true;
      this.$refs.editDropdown.showDropdown();
      debounce(() => {
        this.setFocus();
      }, 50)();
    },
    hideDropdown() {
      this.isEditing = false;
    },
    setSearch(search) {
      this.search = search;
    },
    toggleDropdownContentsCreateView() {
      this.showDropdownContentsCreateView = !this.showDropdownContentsCreateView;
    },
    toggleDropdownContent() {
      this.toggleDropdownContentsCreateView();
      // Required to recalculate dropdown position as its size changes
      if (this.$refs.editDropdown?.$refs.dropdown?.$refs.dropdown) {
        this.$refs.editDropdown.$refs.dropdown.$refs.dropdown.$_popper.scheduleUpdate();
      }
    },
    setFocus() {
      this.$refs.header?.focusInput();
    },
  },
  i18n: {
    label: s__('BoardScope|Labels'),
    anyLabel: s__('BoardScope|Any label'),
    selectLabel: s__('BoardScope|Choose labels'),
    dropdownTitleText: s__('BoardScope|Select labels'),
    errorSearchingLabels: s__(
      'BoardScope|An error occurred while searching for labels, please try again.',
    ),
    edit: s__('BoardScope|Edit'),
  },
};
</script>

<template>
  <div class="block labels labels-select-wrapper">
    <div class="title gl-mb-3">
      {{ $options.i18n.label }}
      <gl-button
        v-if="canEdit"
        category="tertiary"
        size="small"
        class="edit-link float-right"
        data-qa-selector="labels_edit_button"
        @click="toggleEdit"
      >
        {{ $options.i18n.edit }}
      </gl-button>
    </div>
    <div class="gl-text-gray-500 gl-mb-2" data-testid="selected-labels">
      <div v-if="isLabelsEmpty">{{ $options.i18n.anyLabel }}</div>
      <dropdown-value
        v-else
        :disable-labels="isLoading"
        :selected-labels="selected"
        :allow-label-remove="canEdit"
        :labels-filter-base-path="''"
        :labels-filter-param="'label_name'"
        class="gl-mb-2"
        @onLabelRemove="onLabelRemove"
      />
    </div>

    <dropdown-widget
      v-show="isEditing"
      ref="editDropdown"
      :select-text="selectText"
      :options="labels"
      :is-loading="isLoading"
      :selected="selected"
      :search-term="search"
      :allow-multiselect="true"
      data-testid="labels-select-contents-list"
      @hide="hideDropdown"
      @set-option="selectLabel"
      @set-search="setSearch"
    >
      <template #header>
        <dropdown-header
          ref="header"
          :search-key="search"
          :labels-create-title="footerCreateLabelTitle"
          :labels-list-title="$options.i18n.dropdownTitleText"
          :show-dropdown-contents-create-view="showDropdownContentsCreateView"
          @toggleDropdownContentsCreateView="toggleDropdownContent"
          @closeDropdown="hideDropdown"
          @input="setSearch"
        />
      </template>
      <template #item="{ item }">
        <label-item :label="item" />
      </template>
      <template v-if="showDropdownContentsCreateView" #default>
        <dropdown-contents-create-view
          :full-path="fullPath"
          :workspace-type="boardType"
          :attr-workspace-path="fullPath"
          :label-create-type="labelType"
          @hideCreateView="toggleDropdownContent"
        />
      </template>
      <template #footer>
        <dropdown-footer
          v-if="!showDropdownContentsCreateView"
          :footer-create-label-title="footerCreateLabelTitle"
          :footer-manage-label-title="footerManageLabelTitle"
          @toggleDropdownContentsCreateView="toggleDropdownContent"
        />
      </template>
    </dropdown-widget>
  </div>
</template>
