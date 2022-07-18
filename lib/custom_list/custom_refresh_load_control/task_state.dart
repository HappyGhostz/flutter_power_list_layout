class TaskState {
  bool refreshing;
  bool loading;
  bool refreshNoMore;
  bool loadNoMore;

  TaskState({
    this.refreshing = false,
    this.loading = false,
    this.refreshNoMore = false,
    this.loadNoMore = false,
  });

  TaskState copy({bool? refreshing, bool? loading, bool? refreshNoMore, bool? loadNoMore}) {
    return TaskState(
      refreshing: refreshing ?? this.refreshing,
      loading: loading ?? this.loading,
      refreshNoMore: refreshNoMore ?? this.refreshNoMore,
      loadNoMore: loadNoMore ?? this.loadNoMore,
    );
  }
}
