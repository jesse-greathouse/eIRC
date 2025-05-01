import LinkifyIt from 'linkify-it';

const linkify = new LinkifyIt();

export function linkifyHtml(input: string): string {
    const matches = linkify.match(input);
    if (!matches) return input;

    let result = '';
    let lastIndex = 0;

    for (const match of matches) {
        const { index, lastIndex: end, text, url } = match;

        // Add text before the link
        result += input.slice(lastIndex, index);

        // Add the link
        result += `<a href="${url}" target="_blank" rel="noopener noreferrer" class="underline text-blue-500 hover:text-blue-700">${text}</a>`;

        lastIndex = end;
    }

    // Add any remaining text
    result += input.slice(lastIndex);
    return result;
}
