import { __ } from '~/locale';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import aiFillDescriptionMutation from 'ee/ai/graphql/fill_mr_description.mutation.graphql';
import {
  mountMarkdownEditor as mountCEMarkdownEditor,
  MR_SOURCE_BRANCH,
  MR_TARGET_BRANCH,
} from '~/vue_shared/components/markdown/mount_markdown_editor';

export function mountMarkdownEditor() {
  const provideEEAiActions = [];

  if (window.gon?.features?.fillInMrTemplate) {
    provideEEAiActions.push({
      title: __('Fill in merge request template'),
      description: __('Replace current template with filled in placeholders'),
      method: 'replace',
      subscriptionVariables() {
        const projectGqlId = convertToGraphQLId(
          /* eslint-disable-next-line @gitlab/require-i18n-strings */
          'Project',
          document.getElementById('merge_request_source_project_id').value,
        );
        return {
          userId: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          resourceId: projectGqlId,
        };
      },
      apolloMutation() {
        /* eslint-disable @gitlab/require-i18n-strings */
        const projectGqlId = convertToGraphQLId(
          'Project',
          document.getElementById('merge_request_source_project_id').value,
        );
        const targetProjectGqlId = convertToGraphQLId(
          'Project',
          document.getElementById('merge_request_target_project_id').value,
        );
        /* eslint-enable @gitlab/require-i18n-strings */
        const sourceBranch = document.querySelector(`[name="${MR_SOURCE_BRANCH}"]`).value;
        const targetBranch = document.querySelector(`[name="${MR_TARGET_BRANCH}"]`).value;
        const mrTitle = document.getElementById('merge_request_title').value;
        const mrDescription = document.getElementById('merge_request_description').value;

        return {
          mutation: aiFillDescriptionMutation,
          variables: {
            source: sourceBranch,
            target: targetBranch,
            templateContent: mrDescription,
            mrTitle,
            projectGqlId,
            targetProjectGqlId,
          },
        };
      },
    });
  }

  return mountCEMarkdownEditor({
    useApollo: true,
    provide: {
      editorAiActions: provideEEAiActions,
    },
  });
}
