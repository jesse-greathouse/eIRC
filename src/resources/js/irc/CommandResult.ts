export class CommandResult {
    constructor(private readonly _promise: Promise<void>) {}

    then(fn: () => void): CommandResult {
        this._promise.then(fn);
        return this;
    }

    catch(fn: (err: Error) => void): CommandResult {
        this._promise.catch(fn);
        return this;
    }
}
