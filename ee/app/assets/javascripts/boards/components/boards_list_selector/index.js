import Vue from 'vue';
import vuexStore from '~/boards/stores';
import boardsStore from '~/boards/stores/boards_store';
import { fullMilestoneId, fullUserId } from '../../boards_util';
import ListContainer from './list_container.vue';

export default Vue.extend({
  components: {
    ListContainer,
  },
  props: {
    listPath: {
      type: String,
      required: true,
    },
    listType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      store: boardsStore,
      vuexStore,
    };
  },
  mounted() {
    this.loadList();
  },
  methods: {
    loadList() {
      return this.store.loadList(this.listPath, this.listType).then(() => {
        this.loading = false;
      });
    },
    filterItems(term, items) {
      const query = term.toLowerCase();

      return items.filter((item) => {
        const name = item.name ? item.name.toLowerCase() : item.title.toLowerCase();
        const foundName = name.indexOf(query) > -1;

        if (this.listType === 'milestones') {
          return foundName;
        }

        const username = item.username.toLowerCase();
        return foundName || username.indexOf(query) > -1;
      });
    },
    prepareListObject(item) {
      const list = {
        title: item.name,
        position: this.store.state.lists.length - 2,
        list_type: this.listType,
      };

      if (this.listType === 'milestones') {
        list.milestone = item;
      } else if (this.listType === 'assignees') {
        list.user = item;
      }

      return list;
    },
    handleItemClick(item) {
      if (!this.vuexStore.getters.getListByTitle(item.title)) {
        if (this.listType === 'milestones') {
          this.vuexStore.dispatch('createList', { milestoneId: fullMilestoneId(item.id) });
        } else if (this.listType === 'assignees') {
          this.vuexStore.dispatch('createList', { assigneeId: fullUserId(item.id) });
        }
      }
    },
  },
  render(createElement) {
    return createElement('list-container', {
      props: {
        loading: this.loading,
        items: this.store.state[this.listType],
        listType: this.listType,
      },
      on: {
        onItemSelect: this.handleItemClick,
      },
    });
  },
});
