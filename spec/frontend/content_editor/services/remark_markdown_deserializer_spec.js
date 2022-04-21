import Bold from '~/content_editor/extensions/bold';
import Blockquote from '~/content_editor/extensions/blockquote';
import BulletList from '~/content_editor/extensions/bullet_list';
import Code from '~/content_editor/extensions/code';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import DescriptionItem from '~/content_editor/extensions/description_item';
import DescriptionList from '~/content_editor/extensions/description_list';
import Details from '~/content_editor/extensions/details';
import DetailsContent from '~/content_editor/extensions/details_content';
import Division from '~/content_editor/extensions/division';
import Figure from '~/content_editor/extensions/figure';
import FigureCaption from '~/content_editor/extensions/figure_caption';
import HardBreak from '~/content_editor/extensions/hard_break';
import Heading from '~/content_editor/extensions/heading';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
import Image from '~/content_editor/extensions/image';
import Italic from '~/content_editor/extensions/italic';
import Link from '~/content_editor/extensions/link';
import ListItem from '~/content_editor/extensions/list_item';
import OrderedList from '~/content_editor/extensions/ordered_list';
import Paragraph from '~/content_editor/extensions/paragraph';
import createRemarkMarkdownDeserializer from '~/content_editor/services/remark_markdown_deserializer';
import { createTestEditor, createDocBuilder } from '../test_utils';

const tiptapEditor = createTestEditor({
  extensions: [
    Blockquote,
    Bold,
    BulletList,
    Code,
    CodeBlockHighlight,
    HardBreak,
    Heading,
    HorizontalRule,
    Image,
    Italic,
    Link,
    ListItem,
    OrderedList,
  ],
});

const {
  builders: {
    doc,
    blockquote,
    bold,
    bulletList,
    code,
    codeBlock,
    heading,
    hardBreak,
    horizontalRule,
    image,
    italic,
    link,
    listItem,
    orderedList,
    paragraph,
  },
} = createDocBuilder({
  tiptapEditor,
  names: {
    blockquote: { nodeType: Blockquote.name },
    bold: { markType: Bold.name },
    bulletList: { nodeType: BulletList.name },
    code: { markType: Code.name },
    codeBlock: { nodeType: CodeBlockHighlight.name },
    details: { nodeType: Details.name },
    detailsContent: { nodeType: DetailsContent.name },
    division: { nodeType: Division.name },
    descriptionItem: { nodeType: DescriptionItem.name },
    descriptionList: { nodeType: DescriptionList.name },
    figure: { nodeType: Figure.name },
    figureCaption: { nodeType: FigureCaption.name },
    hardBreak: { nodeType: HardBreak.name },
    heading: { nodeType: Heading.name },
    horizontalRule: { nodeType: HorizontalRule.name },
    image: { nodeType: Image.name },
    italic: { nodeType: Italic.name },
    link: { markType: Link.name },
    listItem: { nodeType: ListItem.name },
    orderedList: { nodeType: OrderedList.name },
    paragraph: { nodeType: Paragraph.name },
  },
});

describe('content_editor/services/remark_markdown_deserializer', () => {
  const mdSetextHeadingOne = `
Heading
one
======
`;
  const mdSetextHeadingTwo = `
Heading
two
-------
`;
  const mdBulletListExample = `
- List item 1
- List item 2
`;
  const mdOrderedListExample = `
1. List item 1
1. List item 2
`;
  const mdNestedListExample = `
- List item 1
  - Sub list item 1
`;
  const mdLooseList = `
- List item 1 paragraph 1

  List item 1 paragraph 2
- List item 2
`;
  const mdBlockquote = `
> This is a blockquote
`;
  const mdBlockquoteWithList = `
> - List item 1
> - List item 2
`;
  const mdIndentedCodeBlock = `
    const fn = () => 'GitLab';
`;
  const mdFencedCodeBlock = `
\`\`\`javascript
  const fn = () => 'GitLab';
\`\`\`\
`;
  const mdFencedCodeBlockEmpty = `
\`\`\`
\`\`\`\
`;
  const mdFencedCodeBlockWithEmptyLines = `
\`\`\`javascript
  const fn = () => 'GitLab';


\`\`\`\
`;
  const mdHardBreak = `
This is a paragraph with a\\
hard line break`;

  let deserializer;

  beforeEach(() => {
    deserializer = createRemarkMarkdownDeserializer();
  });

  it.each`
    markdown                                                       | createDoc
    ${'__bold text__'}                                             | ${() => doc(paragraph(bold('bold text')))}
    ${'**bold text**'}                                             | ${() => doc(paragraph(bold('bold text')))}
    ${'<strong>bold text</strong>'}                                | ${() => doc(paragraph(bold('bold text')))}
    ${'<b>bold text</b>'}                                          | ${() => doc(paragraph(bold('bold text')))}
    ${'_italic text_'}                                             | ${() => doc(paragraph(italic('italic text')))}
    ${'*italic text*'}                                             | ${() => doc(paragraph(italic('italic text')))}
    ${'<em>italic text</em>'}                                      | ${() => doc(paragraph(italic('italic text')))}
    ${'<i>italic text</i>'}                                        | ${() => doc(paragraph(italic('italic text')))}
    ${'---'}                                                       | ${() => doc(horizontalRule())}
    ${'***'}                                                       | ${() => doc(horizontalRule())}
    ${'___'}                                                       | ${() => doc(horizontalRule())}
    ${'<hr>'}                                                      | ${() => doc(horizontalRule())}
    ${'[GitLab](https://gitlab.com "Go to GitLab")'}               | ${() => doc(paragraph(link({ href: 'https://gitlab.com', title: 'Go to GitLab' }, 'GitLab')))}
    ${'![GitLab Logo](https://gitlab.com/logo.png "GitLab Logo")'} | ${() => doc(paragraph(image({ src: 'https://gitlab.com/logo.png', alt: 'GitLab Logo', title: 'GitLab Logo' })))}
    ${'`inline code`'}                                             | ${() => doc(paragraph(code('inline code')))}
    ${'# Heading 1'}                                               | ${() => doc(heading({ level: 1 }, 'Heading 1'))}
    ${'## Heading 2'}                                              | ${() => doc(heading({ level: 2 }, 'Heading 2'))}
    ${'### Heading 3'}                                             | ${() => doc(heading({ level: 3 }, 'Heading 3'))}
    ${'#### Heading 4'}                                            | ${() => doc(heading({ level: 4 }, 'Heading 4'))}
    ${'##### Heading 5'}                                           | ${() => doc(heading({ level: 5 }, 'Heading 5'))}
    ${'###### Heading 6'}                                          | ${() => doc(heading({ level: 6 }, 'Heading 6'))}
    ${mdSetextHeadingOne}                                          | ${() => doc(heading({ level: 1 }, 'Heading\none'))}
    ${mdSetextHeadingTwo}                                          | ${() => doc(heading({ level: 2 }, 'Heading\ntwo'))}
    ${mdBulletListExample}                                         | ${() => doc(bulletList(listItem(paragraph('List item 1')), listItem(paragraph('List item 2'))))}
    ${mdOrderedListExample}                                        | ${() => doc(orderedList(listItem(paragraph('List item 1')), listItem(paragraph('List item 2'))))}
    ${mdNestedListExample}                                         | ${() => doc(bulletList(listItem(paragraph('List item 1'), bulletList(listItem(paragraph('Sub list item 1'))))))}
    ${mdLooseList}                                                 | ${() => doc(bulletList(listItem(paragraph('List item 1 paragraph 1'), paragraph('List item 1 paragraph 2')), listItem(paragraph('List item 2'))))}
    ${mdBlockquote}                                                | ${() => doc(blockquote(paragraph('This is a blockquote')))}
    ${mdBlockquoteWithList}                                        | ${() => doc(blockquote(bulletList(listItem(paragraph('List item 1')), listItem(paragraph('List item 2')))))}
    ${mdIndentedCodeBlock}                                         | ${() => doc(codeBlock({ language: '' }, "const fn = () => 'GitLab';\n"))}
    ${mdFencedCodeBlock}                                           | ${() => doc(codeBlock({ language: 'javascript' }, "  const fn = () => 'GitLab';\n"))}
    ${mdFencedCodeBlockEmpty}                                      | ${() => doc(codeBlock({ language: '' }, ''))}
    ${mdFencedCodeBlockWithEmptyLines}                             | ${() => doc(codeBlock({ language: 'javascript' }, "  const fn = () => 'GitLab';\n\n\n"))}
    ${mdHardBreak}                                                 | ${() => doc(paragraph('This is a paragraph with a', hardBreak(), '\nhard line break'))}
  `('deserializes $markdown correctly', async ({ markdown, createDoc }) => {
    const { schema } = tiptapEditor;
    const expectedDoc = createDoc();
    const { document } = await deserializer.deserialize({ schema, content: markdown });

    expect(document.toJSON()).toEqual(expectedDoc.toJSON());
  });
});
