export type TaskId = string;
export type SessionInfo = {
  id: string;
  cwd: string;
};

export class GlobalState {
  private allTasks: Record<TaskId, SessionInfo> = {};
  private navStack: (SessionInfo & { taskId: TaskId })[] = [];

  addTask(taskId: TaskId, sessionId: string, cwd: string) {
    this.allTasks[taskId] = { id: sessionId, cwd: cwd };
  }

  /**
   * Pushes to the stack. Returns true if failed due to task not existing.
   */
  pushStack(taskId: TaskId): boolean {
    const sessionInfo = this.allTasks[taskId];
    if (!sessionInfo) return true;
    this.navStack.push({ ...sessionInfo, taskId: taskId });
    return false;
  }

  /**
   * Pops from the stack. Returns true if failed due to stack being empty
   */
  popStack(): boolean {
    if (this.navStack.length == 0) return true;
    this.navStack.pop();
    return false;
  }
}
