<script>
// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
/* eslint-disable @gitlab/no-runtime-template-compiler */
import { mapGetters } from 'vuex';
import BoardFormFoss from '~/boards/components/board_form.vue';
import createEpicBoardMutation from '../graphql/epic_board_create.mutation.graphql';
import destroyEpicBoardMutation from '../graphql/epic_board_destroy.mutation.graphql';
import updateEpicBoardMutation from '../graphql/epic_board_update.mutation.graphql';

export default {
  extends: BoardFormFoss,
  computed: {
    ...mapGetters(['isEpicBoard']),
    currentEpicBoardMutation() {
      return this.board.id ? updateEpicBoardMutation : createEpicBoardMutation;
    },
    mutationVariables() {
      return {
        ...this.baseMutationVariables,
        ...(this.scopedIssueBoardFeatureEnabled || this.isEpicBoard
          ? this.boardScopeMutationVariables
          : {}),
      };
    },
  },
  methods: {
    epicBoardCreateResponse(data) {
      return data.epicBoardCreate.epicBoard.webPath;
    },
    epicBoardUpdateResponse(data) {
      return data.epicBoardUpdate.epicBoard.webPath;
    },
    async createOrUpdateBoard() {
      const response = await this.$apollo.mutate({
        mutation: this.isEpicBoard ? this.currentEpicBoardMutation : this.currentMutation,
        variables: { input: this.mutationVariables },
      });

      if (!this.board.id) {
        return this.isEpicBoard
          ? this.epicBoardCreateResponse(response.data)
          : this.boardCreateResponse(response.data);
      }

      return this.isEpicBoard
        ? this.epicBoardUpdateResponse(response.data)
        : this.boardUpdateResponse(response.data);
    },
    async deleteBoard() {
      await this.$apollo.mutate({
        mutation: this.isEpicBoard ? destroyEpicBoardMutation : this.deleteMutation,
        variables: {
          id: this.board.id,
        },
      });
    },
  },
};
</script>
