import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  OperationCancelledError,
  OperationTimedOutError,
  runBounded,
} from "./apple-account.ts";

Deno.test("runBounded times out and cancels the underlying operation", async () => {
  let operationWasCancelled = false;
  try {
    await runBounded(
      (signal) =>
        new Promise((_resolve, reject) => {
          signal.addEventListener("abort", () => {
            operationWasCancelled = true;
            reject(new DOMException("aborted", "AbortError"));
          }, { once: true });
        }),
      1,
    );
    throw new Error("Expected timeout");
  } catch (error) {
    assert(error instanceof OperationTimedOutError);
  }
  assertEquals(operationWasCancelled, true);
});

Deno.test("runBounded propagates parent cancellation and aborts work", async () => {
  const parent = new AbortController();
  let operationWasCancelled = false;
  const task = runBounded(
    (signal) =>
      new Promise((_resolve, reject) => {
        signal.addEventListener("abort", () => {
          operationWasCancelled = true;
          reject(new DOMException("aborted", "AbortError"));
        }, { once: true });
      }),
    1_000,
    parent.signal,
  );
  parent.abort();

  try {
    await task;
    throw new Error("Expected cancellation");
  } catch (error) {
    assert(error instanceof OperationCancelledError);
  }
  assertEquals(operationWasCancelled, true);
});
