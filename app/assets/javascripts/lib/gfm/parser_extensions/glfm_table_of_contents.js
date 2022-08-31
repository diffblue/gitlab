import { last } from 'lodash';
import { u } from 'unist-builder';
import { is } from 'unist-util-is';
import { visitParents, SKIP, CONTINUE } from 'unist-util-visit-parents';

const isTOCTextNode = (node) => is(node, { type: 'text', value: 'TOC' });

/*
 * Detects table of contents declaration with syntax [[_TOC_]]
 */
const isTableOfContentsDoubleSquareBracketSyntax = ({ children }) => {
  if (children.length !== 3) {
    return false;
  }

  const [firstChild, middleChild, lastChild] = children;

  return (
    is(firstChild, ({ type, value }) => type === 'text' && value.trim() === '[[') &&
    is(
      middleChild,
      ({ type, children: emChildren }) =>
        type === 'emphasis' && emChildren.length === 1 && isTOCTextNode(emChildren[0]),
    ) &&
    is(lastChild, { type: 'text', value: ']]' })
  );
};

/*
 * Detects table of contents declaration with syntax [TOC]
 */
const isTableOfContentsSingleSquareBracketSyntax = ({ children }) => {
  if (children.length !== 1) {
    return false;
  }

  const [firstChild] = children;

  return is(firstChild, ({ type, value }) => type === 'text' && value.trim() === '[TOC]');
};

const isTableOfContentsNode = (node) =>
  node.type === 'paragraph' &&
  (isTableOfContentsDoubleSquareBracketSyntax(node) ||
    isTableOfContentsSingleSquareBracketSyntax(node));

export default () => {
  return (tree) => {
    visitParents(tree, (node, ancestors) => {
      const parent = last(ancestors);

      if (!parent) {
        return CONTINUE;
      }

      if (isTableOfContentsNode(node)) {
        const index = parent.children.indexOf(node);

        parent.children[index] = u('tableOfContents', {
          position: node.position,
        });
      }

      return SKIP;
    });

    return tree;
  };
};
