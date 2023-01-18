<script>
import IndexEntitiesSelector from './index_entities_selector.vue';
import IndexEntitiesList from './index_entities_list.vue';

export default {
  components: {
    IndexEntitiesSelector,
    IndexEntitiesList,
  },
  props: {
    initialSelection: {
      type: Array,
      required: false,
      default: () => [],
    },
    inputName: {
      type: String,
      required: true,
    },
    apiPath: {
      type: String,
      required: true,
    },
    selectorToggleText: {
      type: String,
      required: true,
    },
    nameProp: {
      type: String,
      required: true,
    },
    emptyListText: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selected: this.initialSelection,
    };
  },
  computed: {
    inputValue() {
      return this.selected.map(({ id }) => id).join(',');
    },
  },
  methods: {
    removeItem(id) {
      this.selected = this.selected.filter((selected) => selected.id !== id);
    },
    onSelect(item) {
      this.selected.push(item);
    },
  },
};
</script>

<template>
  <div>
    <index-entities-selector
      class="gl-mb-3"
      :selected="selected"
      :api-path="apiPath"
      :toggle-text="selectorToggleText"
      :name-prop="nameProp"
      @select="onSelect"
    />

    <index-entities-list :entities="selected" :empty-text="emptyListText" @remove="removeItem" />

    <input type="hidden" :name="inputName" :value="inputValue" />
  </div>
</template>
