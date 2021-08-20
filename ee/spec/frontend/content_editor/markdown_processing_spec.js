import path from 'path';
import {
  createSharedExamples,
  loadMarkdownApiExamples,
} from 'jest/content_editor/markdown_processing_spec_helper';

jest.mock('~/emoji');

// See spec/fixtures/markdown/markdown_golden_master_examples.yml for documentation on how this spec works.
describe('EE markdown processing in ContentEditor', () => {
  // Ensure we generate same markdown that was provided to Markdown API.
  const markdownYamlPath = path.join(
    __dirname,
    '..',
    '..',
    'fixtures',
    'markdown',
    'markdown_golden_master_examples.yml',
  );
  // eslint-disable-next-line jest/valid-describe
  describe.each(loadMarkdownApiExamples(markdownYamlPath))('%s', createSharedExamples);
});
