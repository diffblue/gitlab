<script>
import { mapActions } from 'vuex';
import BoardsSelectorFoss from '~/boards/components/boards_selector.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import Tracking from '~/tracking';
import epicBoardsQuery from '../graphql/epic_boards.query.graphql';
import { fullBoardId, fullEpicBoardId } from '../boards_util';

// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
// eslint-disable-next-line @gitlab/no-runtime-template-compiler
export default {
  extends: BoardsSelectorFoss,
  mixins: [Tracking.mixin()],
  inject: ['isEpicBoard'],
  computed: {
    showCreate() {
      return this.isEpicBoard || this.multipleIssueBoardsAvailable;
    },
  },
  methods: {
    ...mapActions(['fetchEpicBoard']),
    fullBoardId(boardId) {
      return this.isEpicBoard ? fullEpicBoardId(boardId) : fullBoardId(boardId);
    },
    epicBoardUpdate(data) {
      if (!data?.group) {
        return [];
      }
      return data.group.epicBoards.nodes.map((node) => ({
        id: getIdFromGraphQLId(node.id),
        name: node.name,
      }));
    },
    epicBoardQuery() {
      return epicBoardsQuery;
    },
    loadBoards(toggleDropdown = true) {
      if (this.isEpicBoard) {
        this.track('click_dropdown', { label: 'board_switcher' });
      }

      if (toggleDropdown && this.boards.length > 0) {
        return;
      }

      this.$apollo.addSmartQuery('boards', {
        variables() {
          return { fullPath: this.fullPath };
        },
        query: this.isEpicBoard ? this.epicBoardQuery : this.boardQuery,
        update: (data) =>
          this.isEpicBoard ? this.epicBoardUpdate(data) : this.boardUpdate(data, 'boards'),
        watchLoading: (isLoading) => {
          this.loadingBoards = isLoading;
        },
      });

      if (!this.isEpicBoard) {
        this.loadRecentBoards();
      }
    },
    fetchCurrentBoard(boardId) {
      if (this.isEpicBoard) {
        this.fetchEpicBoard({
          fullPath: this.fullPath,
          boardId: fullEpicBoardId(boardId),
        });
      } else {
        this.fetchBoard({
          fullPath: this.fullPath,
          fullBoardId: fullBoardId(boardId),
          boardType: this.boardType,
        });
      }
    },
  },
};
</script>
