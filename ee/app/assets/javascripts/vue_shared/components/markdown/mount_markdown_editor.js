import { __ } from '~/locale';
import { TYPENAME_USER, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { generateDescriptionAction } from 'ee/ai/editor_actions/generate_description';
import aiFillDescriptionMutation from 'ee/ai/graphql/fill_mr_description.mutation.graphql';
import { mountMarkdownEditor as mountCEMarkdownEditor } from '~/vue_shared/components/markdown/mount_markdown_editor';
import { MergeRequestGeneratedContent } from '~/merge_requests/generated_content';

export function mountMarkdownEditor() {
  const provideEEAiActions = [];
  let mrGeneratedContent;

  if (window.gon?.features?.fillInMrTemplate) {
    mrGeneratedContent = new MergeRequestGeneratedContent();

    provideEEAiActions.push({
      title: __('Fill in merge request template'),
      description: __('Replace current template with filled in placeholders'),
      method: 'replace',
      subscriptionVariables() {
        const mrMetadata = document.getElementById('js-merge-request-metadata');
        return {
          userId: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          resourceId: convertToGraphQLId(TYPENAME_PROJECT, mrMetadata.dataset.targetProjectId),
        };
      },
      apolloMutation() {
        const mrMetadata = document.getElementById('js-merge-request-metadata');
        const { sourceProjectId, sourceBranch, targetProjectId, targetBranch } = mrMetadata.dataset;
        const targetProjectGqlId = convertToGraphQLId(TYPENAME_PROJECT, targetProjectId);
        const mrTitle = document.getElementById('merge_request_title').value;
        const mrDescription = document.getElementById('merge_request_description').value;

        return {
          mutation: aiFillDescriptionMutation,
          variables: {
            source: sourceBranch,
            target: targetBranch,
            templateContent: mrDescription,
            mrTitle,
            sourceProjectId,
            targetProjectGqlId,
          },
        };
      },
    });
  }

  if (window.gon?.features?.generateDescriptionAi) {
    provideEEAiActions.push(generateDescriptionAction());
  }

  const editor = mountCEMarkdownEditor({
    useApollo: true,
    provide: {
      editorAiActions: provideEEAiActions,
      mrGeneratedContent,
    },
  });

  mrGeneratedContent?.setEditor(editor);

  return editor;
}
