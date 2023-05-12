import { nextTick } from 'vue';
import Markdown from 'ee/ci/pipeline_editor/components/markdown.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

describe('AiGenieMarkdown', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(Markdown, {
      propsData,
    });
  };

  const codeBlockContent = 'stages:\n  - build\n  - test\n  - deploy\n';
  const codeBlockLanguage = 'yaml';
  const nonCodeContent =
    "Certainly! Here's an updated GitLab CI/CD configuration in YAML format that includes Kubernetes deployment:";
  const testMarkdownWithCodeBlock = `${nonCodeContent}\n\n\`\`\`${codeBlockLanguage}\n${codeBlockContent}\n\`\`\`\n\nIn this updated configuration, we have added a \`deploy\` job that deploys the Python app to a Kubernetes cluster. The \`script\` section of the job includes commands to authenticate with GCP, set the project and zone, configure kubectl to use the GKE cluster, and deploy the application using a deployment.yaml file.\n\nNote that you will need to modify this configuration to fit your specific deployment needs, including replacing the placeholders (\`<PROJECT_ID>\`, \`<COMPUTE_ZONE>\`, \`<CLUSTER_NAME>\`, and \`<COMPUTE_REGION>\`) with your GCP and Kubernetes deployment information, and creating the deployment.yaml file with your Kubernetes deployment configuration.`;
  const codeOnlyMarkdown = `\`\`\`${codeBlockLanguage}\n${codeBlockContent}\n\`\`\``;

  const findCodeBlock = () => wrapper.findComponent(CodeBlockHighlighted);
  const findCopyCodeButton = () => wrapper.findComponent(ModalCopyButton);
  const findCodeBlockWrapper = () => wrapper.find('[data-testid="code-block-wrapper"');
  const findMarkdownBlock = () => wrapper.find('[data-testid="non-code-markdown"');

  describe('rendering markdown without code snippet', () => {
    beforeEach(() => {
      createComponent({ propsData: { markdown: nonCodeContent } });
    });
    it('should render non-code content', () => {
      const markdownBlock = findMarkdownBlock();
      expect(markdownBlock.exists()).toBe(true);
      expect(markdownBlock.text()).toContain(nonCodeContent);
    });
    it('should not render code block', () => {
      const codeBlock = findCodeBlock();
      expect(codeBlock.exists()).toBe(false);
    });
  });

  describe('rendering code snippet without other markdown', () => {
    beforeEach(() => {
      createComponent({ propsData: { markdown: codeOnlyMarkdown } });
    });
    it('should not render non-code content', () => {
      const markdownBlock = findMarkdownBlock();
      expect(markdownBlock.exists()).toBe(false);
    });
    it('should render code block', () => {
      const codeBlock = findCodeBlock();
      expect(codeBlock.exists()).toBe(true);
    });
  });

  describe('rendering markdown with multiple code snippets', () => {
    beforeEach(() => {
      const markdownWithMultipleCodeSnippets = `${testMarkdownWithCodeBlock}\n${testMarkdownWithCodeBlock}`;
      createComponent({ propsData: { markdown: markdownWithMultipleCodeSnippets } });
    });

    it('should render code block with correct props', () => {
      const codeBlock = findCodeBlock();
      expect(codeBlock.exists()).toBe(true);
      expect(codeBlock.props()).toEqual(
        expect.objectContaining({
          language: codeBlockLanguage,
          code: codeBlockContent,
        }),
      );
    });

    it('should not show copy code button', () => {
      const copyCodeButton = findCopyCodeButton();
      expect(copyCodeButton.exists()).toBe(false);
    });

    it('should render non-code content', () => {
      const markdownBlock = findMarkdownBlock();
      expect(markdownBlock.exists()).toBe(true);
      expect(markdownBlock.text()).toContain(nonCodeContent);
    });

    describe('copy code button', () => {
      beforeEach(() => {
        const codeBlock = findCodeBlockWrapper();
        codeBlock.trigger('mouseenter');
      });

      it('should render only one copy button per code block', () => {
        const copyCodeButtons = wrapper.findAllComponents(ModalCopyButton);
        expect(copyCodeButtons.length).toBe(1);
      });

      it('should render code block button with correct props', () => {
        const copyCodeButton = findCopyCodeButton();
        expect(copyCodeButton.exists()).toBe(true);
        expect(copyCodeButton.props()).toEqual(
          expect.objectContaining({
            text: codeBlockContent,
            title: 'Copy code',
          }),
        );
      });

      it('should hide code block button on mouseleave', async () => {
        const codeBlock = findCodeBlockWrapper();
        codeBlock.trigger('mouseleave');
        await nextTick();
        const copyCodeButton = findCopyCodeButton();
        expect(copyCodeButton.exists()).toBe(false);
      });
    });
  });
});
