import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/scheduler.dart';
import 'package:glasswork/intel/add_preview.dart';
import 'package:glasswork/intel/project_match.dart';
import 'package:glasswork/intel/task_suggest.dart';

/// Adding a task, made smarter offline: which project an @ names, what your own history
/// suggests, and whether it will fit — each pure, against fixed data.
void main() {
  final now = DateTime(2026, 9, 11, 9); // a Friday

  group('@project', () {
    const projects = [
      (id: 'gw', name: 'Glasswork'),
      (id: 'vm', name: 'Voxtrona Music'),
      (id: 'pbl', name: 'PBL'),
      (id: 'rw', name: 'Regular Works'),
    ];
    String? best(String hint) => ProjectMatch.best(hint, projects, now: now);

    test('the whole name, its start, or a word in it', () {
      expect(best('glasswork'), 'gw');
      expect(best('glass'), 'gw');
      expect(best('music'), 'vm');
      expect(best('PBL'), 'pbl');
      expect(best('regular-works'), 'rw', reason: 'a hyphen stands for the space an @ cannot hold');
    });

    test('nothing, when nothing comes close', () {
      expect(best('dentist'), isNull);
      expect(ProjectMatch.best(null, projects, now: now), isNull);
      expect(ProjectMatch.best('gw', const [], now: now), isNull);
    });
  });

  group('suggestions from history', () {
    const history = [
      PastTask(title: 'DBMS lab report', projectId: 'uni', labels: ['dbms'], estimateMin: 120),
      PastTask(title: 'DBMS lab viva prep', projectId: 'uni', labels: ['dbms', 'exam'], trackedMin: 90),
      PastTask(title: 'Submit DBMS lab', projectId: 'uni', labels: ['dbms'], estimateMin: 60),
      PastTask(title: 'Buy groceries', projectId: 'home', estimateMin: 30),
    ];

    test('the project, labels and estimate the alike tasks share', () {
      final s = TaskSuggest.suggest('dbms lab 5', history);
      expect(s.projectId, 'uni');
      expect(s.labels, ['dbms'], reason: 'exam is on one of three, so not offered');
      expect(s.estimateMin, 90, reason: 'the middle of 120, 90 tracked and 60');
      expect(s.basedOn, 3);
    });

    test('nothing from tasks that are not alike', () {
      expect(TaskSuggest.suggest('call the dentist', history).isEmpty, isTrue);
      expect(TaskSuggest.suggest('', history).isEmpty, isTrue);
    });

    test('one past task is enough only when it is very like this one', () {
      expect(TaskSuggest.suggest('buy groceries', history).estimateMin, 30);
      expect(
        TaskSuggest.suggest('buy new shoes and groceries for the trip', history).isEmpty,
        isTrue,
        reason: 'one word in six in common',
      );
    });

    test('plurals and capitals agree', () {
      expect(TaskSuggest.suggest('DBMS LABS', history).projectId, 'uni');
    });
  });

  group('will it fit', () {
    ScheduledTask plan({required int slack, int shortfall = 0, DateTime? start, DateTime? finish}) =>
        ScheduledTask(
          task: PlannedTask(id: 'x', title: 'x', dueDay: DateTime(2026, 9, 17), estimateMin: 60),
          startDay: start ?? DateTime(2026, 9, 11),
          finishDay: finish ?? DateTime(2026, 9, 15),
          slackDays: slack,
          shortfallMin: shortfall,
        );

    test('in a sentence, with the day it is done by', () {
      expect(AddPreview.sentence(plan(slack: 2), today: now), 'Fits — done by Tuesday, 2 days to spare');
      expect(
        AddPreview.sentence(plan(slack: 1, finish: DateTime(2026, 9, 12)), today: now),
        'Fits — done by tomorrow, 1 day to spare',
      );
      expect(AddPreview.sentence(plan(slack: 0), today: now), 'Tight — done on the day it is due, nothing spare. Start today.');
      expect(
        AddPreview.sentence(plan(slack: 0, shortfall: 90), today: now),
        "Won't fit by Thursday — 1h 30m short. Start today.",
      );
      expect(AddPreview.sentence(plan(slack: -2), today: now), "Won't fit — 2 days past Thursday");
    });

    test('nothing to say without a deadline', () {
      expect(AddPreview.sentence(null, today: now), isNull);
    });
  });
}
