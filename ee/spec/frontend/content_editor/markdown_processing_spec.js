import path from 'path';
import { describeMarkdownProcessing } from 'jest/content_editor/markdown_processing_spec_helper';

jest.mock('~/emoji');

const markdownYamlPath = path.join(
  __dirname,
  '..',
  '..',
  'fixtures',
  'markdown',
  'markdown_golden_master_examples.yml',
);

// See spec/fixtures/markdown/markdown_golden_master_examples.yml for documentation on how this spec works.
describeMarkdownProcessing('EE markdown processing in ContentEditor', markdownYamlPath);
