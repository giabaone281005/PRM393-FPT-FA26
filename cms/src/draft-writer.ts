import { clone, payload, type Lesson } from "./domain";
import type { Repository } from "./repository";

export type PendingWrite = {
  operation: string;
  revision: number;
  document: Lesson;
};
export const fingerprint = (doc: Lesson) => JSON.stringify(payload(doc));

/** Serial, idempotent writes. A failed request is retried unchanged before newer edits. */
export class DraftWriter {
  private pending?: PendingWrite;
  private running?: Promise<void>;
  private latest?: Lesson;
  saved = "";
  constructor(
    private repository: Repository,
    public revision: number,
    private checkpoint: (pending?: PendingWrite) => void = () => {},
    restored?: PendingWrite,
  ) {
    this.pending = restored;
  }
  save(doc: Lesson): Promise<void> {
    this.latest = clone(doc);
    if (this.running) return this.running;
    this.running = this.drain().finally(() => {
      this.running = undefined;
    });
    return this.running;
  }
  private async drain() {
    while (
      this.pending ||
      (this.latest && fingerprint(this.latest) !== this.saved)
    ) {
      if (!this.pending) {
        this.pending = {
          operation: crypto.randomUUID(),
          revision: this.revision,
          document: clone(this.latest!),
        };
        this.checkpoint(this.pending);
      }
      const request = this.pending;
      this.revision = await this.repository.saveDraft(
        request.document,
        request.revision,
        request.operation,
      );
      this.saved = fingerprint(request.document);
      this.pending = undefined;
      this.checkpoint();
    }
  }
}
