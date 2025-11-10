import 'package:flutter/material.dart';

import '../models/task.dart';

int taskStatusToIndex(TaskStatus status) => status.index;

TaskStatus taskStatusFromIndex(int index) => TaskStatus.values[index];

int themeModeToIndex(ThemeMode mode) => mode.index;

ThemeMode themeModeFromIndex(int index) => ThemeMode.values[index];
