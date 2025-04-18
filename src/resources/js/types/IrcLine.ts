export interface IrcLineSerialized {
  id: string;
  timestamp: number;
  raw: string;
  prefix?: string | null;
  command: string;
  params: string[];
  tags?: Record<string, string>;
}

export class IrcLine {
  id: string;
  timestamp: number;
  raw: string;
  prefix?: string | null;
  command: string;
  params: string[];
  tags?: Record<string, string>;

  constructor(data: IrcLineSerialized) {
    this.id = data.id;
    this.timestamp = data.timestamp;
    this.raw = data.raw;
    this.prefix = data.prefix ?? null;
    this.command = data.command;
    this.params = data.params;
    this.tags = data.tags ?? {};
  }

  serialize(): string {
    return JSON.stringify(this.toObject());
  }

  toObject(): IrcLineSerialized {
    return {
      id: this.id,
      timestamp: this.timestamp,
      raw: this.raw,
      prefix: this.prefix,
      command: this.command,
      params: this.params,
      tags: this.tags,
    };
  }

  static unserialize(serialized: string): IrcLine {
    const parsed = JSON.parse(serialized);
    return new IrcLine(parsed);
  }
}
