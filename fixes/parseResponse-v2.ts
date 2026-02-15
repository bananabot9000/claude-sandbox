interface ParsedReply {
  replyTo?: string;
  ping?: boolean;
  delay?: number;
  message: string;
}

/**
 * Block delimiter: U+241E ␞ (Symbol for Record Separator)
 *
 * Previously used `---` on its own line, but this caused false splits when
 * the bot included `---` in code blocks, YAML frontmatter, or markdown HR.
 * See: PR #17 (original fix), and the Great YAML Frontmatter Incident of
 * 15 February 2026 where a skill-aware permissions discussion was eaten.
 *
 * U+241E was chosen because:
 * - It's a single Unicode character the model can reliably generate
 * - It would never appear in natural text, code, or markdown
 * - It semantically IS a record separator (designed for this in 1963)
 * - It's visible in raw data (easier to debug than zero-width chars)
 * - It survives the full pipeline: model → SDK → ears → parser
 *
 * Backwards compatibility: also supports `---` on its own line as a
 * fallback, but only when not inside a fenced code block (``` ... ```).
 */
const RECORD_SEPARATOR = '\u241E';

export function parseResponse(raw: string): ParsedReply[] {
  const blocks = splitBlocks(raw).filter((b) => b.trim().length > 0);

  return blocks
    .map((block) => {
      const lines = block.trim().split('\n');
      let replyTo: string | undefined;
      let ping: boolean | undefined;
      let delay: number | undefined;
      const messageLines: string[] = [];
      let inMessage = false;

      for (const line of lines) {
        if (!inMessage && line.startsWith('replyTo:')) {
          replyTo = line.slice('replyTo:'.length).trim();
        } else if (!inMessage && line.startsWith('ping:')) {
          ping = line.slice('ping:'.length).trim().toLowerCase() === 'true';
        } else if (!inMessage && line.startsWith('delay:')) {
          const parsed = Number(line.slice('delay:'.length).trim());
          if (!Number.isNaN(parsed) && parsed > 0) {
            delay = parsed;
          }
        } else if (line.startsWith('message:')) {
          inMessage = true;
          const rest = line.slice('message:'.length).trimStart();
          if (rest.length > 0) {
            messageLines.push(rest);
          }
        } else if (inMessage) {
          messageLines.push(line);
        }
      }

      return {
        replyTo,
        ping,
        delay,
        message: messageLines.join('\n').trim(),
      } satisfies ParsedReply;
    })
    .filter((r) => r.message.length > 0);
}

function splitBlocks(raw: string): string[] {
  // Primary: split on U+241E (Record Separator symbol)
  if (raw.includes(RECORD_SEPARATOR)) {
    return raw.split(RECORD_SEPARATOR);
  }

  // Fallback: split on --- but only outside fenced code blocks
  return splitOnDashesOutsideCodeBlocks(raw);
}

function splitOnDashesOutsideCodeBlocks(raw: string): string[] {
  const lines = raw.split('\n');
  const blocks: string[] = [];
  let currentBlock: string[] = [];
  let inCodeFence = false;

  for (const line of lines) {
    // Track fenced code blocks (``` or ~~~)
    if (/^[\s]*(`{3,}|~{3,})/.test(line)) {
      inCodeFence = !inCodeFence;
      currentBlock.push(line);
      continue;
    }

    // Only split on --- when outside code fences
    if (!inCodeFence && /^\s*---\s*$/.test(line)) {
      blocks.push(currentBlock.join('\n'));
      currentBlock = [];
      continue;
    }

    currentBlock.push(line);
  }

  // Don't forget the last block
  if (currentBlock.length > 0) {
    blocks.push(currentBlock.join('\n'));
  }

  return blocks;
}
