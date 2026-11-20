import 'package:flutter_test/flutter_test.dart';
import 'package:aonego9_user/data/programs.dart';
import 'package:aonego9_user/data/taxonomy.dart';

void main() {
  group('EventPlanner', () {
    for (final type in plannerEventTypes) {
      test('$type: budget split sums to the budget', () {
        final p = EventPlanner.plan(type: type, guests: 250, budget: 400000, city: 'Pune');
        final share = p.budgetLines.fold<double>(0, (a, l) => a + l.share);
        expect(share, closeTo(1.0, 0.001));
        final total = p.budgetLines.fold<double>(0, (a, l) => a + l.amount);
        expect(total, closeTo(400000, p.budgetLines.length.toDouble()));
        expect(p.timeline, isNotEmpty);
        expect(p.checklist, isNotEmpty);
      });
    }

    test('every budget head that links to a category links to a real one', () {
      for (final type in plannerEventTypes) {
        final p = EventPlanner.plan(type: type, guests: 100, budget: 100000, city: 'Delhi');
        for (final l in p.budgetLines.where((l) => l.catId.isNotEmpty)) {
          expect(catById.containsKey(l.catId), isTrue, reason: '${l.label} → ${l.catId}');
        }
      }
    });

    test('large events get the crowd plan and a longer runway', () {
      final p = EventPlanner.plan(type: 'Festival / fest', guests: 1200, budget: 2000000, city: 'Mumbai');
      expect(p.checklist.any((c) => c.contains('Security')), isTrue);
      expect(p.timeline.first.when, '12 weeks before');
    });
  });

  group('Notebook', () {
    test('round-trips through JSON with guests, accounts, tasks and history', () {
      final plan = EventPlanner.plan(type: 'Anniversary', guests: 80, budget: 150000, city: 'Jaipur');
      final nb = Notebook.fromPlan(plan, id: 'n1', date: '2026-12-31');
      expect(nb.expenses, isEmpty, reason: 'the ledger is for real quotes, not the plan');
      expect(nb.notes, contains('Planned budget split'));
      nb.guests.add(NbGuest(name: 'Asha', party: 2, rsvp: 'Confirmed'));
      nb.guests.add(NbGuest(name: 'Ravi', rsvp: 'Declined'));
      nb.expenses.add(NbExpense(label: 'Venue advance', amount: 40000, paid: true));
      nb.expenses.add(NbExpense(label: 'Sound', amount: 15000));
      nb.tasks.first.done = true;

      final back = Notebook.decodeAll(Notebook.encodeAll([nb])).single;
      expect(back.id, 'n1');
      expect(back.guests.length, 2);
      expect(back.headcount, 2); // declined guests don't count
      expect(back.confirmed, 2);
      expect(back.spent, closeTo(nb.spent, 0.01));
      expect(back.spent, closeTo(55000, 0.01));
      expect(back.paid, closeTo(40000, 0.01));
      expect(back.remaining, closeTo(150000 - 55000, 0.01));
      expect(back.tasksDone, 1);
      expect(back.history, isNotEmpty);
    });

    test('corrupt storage decodes to an empty list instead of throwing', () {
      expect(Notebook.decodeAll('not json'), isEmpty);
      expect(Notebook.decodeAll('{"a":1}'), isEmpty);
    });
  });

  group('event sectors', () {
    test('education and entertainment are told apart', () {
      expect(eventSectorOf({'title': 'Makeup masterclass'}), 'education');
      expect(eventSectorOf({'title': 'Admission open day', 'type': ''}), 'education');
      expect(eventSectorOf({'title': 'Summer fashion night'}), 'entertainment');
      expect(eventSectorOf({'title': 'Anything', 'sector': 'Education'}), 'education');
    });

    test('type chips match loosely', () {
      expect(eventMatchesType({'title': 'Lakme Fashion Week'}, 'Fashion shows'), isTrue);
      expect(eventMatchesType({'title': 'New Year bash'}, 'Festivals'), isTrue);
      expect(eventMatchesType({'title': 'Casting call — ad film'}, 'Castings'), isTrue);
      expect(eventMatchesType({'title': 'Casting call'}, 'Webinars'), isFalse);
    });
  });

  group('parsing', () {
    test('campaign reads city interest as a map or a list', () {
      final a = Campaign.fromJson({'id': 1, 'title': 'X', 'city_interest': {'Mumbai': 12, 'Pune': 3}});
      final b = Campaign.fromJson({'id': 2, 'title': 'Y', 'city_interest': [{'city': 'Delhi', 'count': 7}]});
      expect(a.cityInterest['Mumbai'], 12);
      expect(b.cityInterest['Delhi'], 7);
      expect(Campaign.fromJson({'title': 'Z', 'type': 'Brand promotion'}).kind, 'brand');
    });

    test('offer codes are normalised', () {
      expect(Offer.fromJson({'title': 'T', 'code': ' shoot20 '}).code, 'SHOOT20');
    });

    test('onboarding profile types point at real categories', () {
      for (final p in profileTypes) {
        for (final id in p.catIds) {
          expect(catById.containsKey(id), isTrue, reason: '${p.id} → $id');
        }
      }
      // Every category the requirements list has an onboarding route.
      for (final id in ['vendor', 'organiser', 'school', 'production', 'modelAgency', 'showOrganiser', 'college', 'media', 'brand', 'star']) {
        expect(profileTypeById(id), isNotNull, reason: id);
      }
    });
  });

  test('inr uses Indian digit grouping', () {
    expect(inr(0), '₹0');
    expect(inr(999), '₹999');
    expect(inr(1000), '₹1,000');
    expect(inr(1234567), '₹12,34,567');
    expect(inr(-50000), '−₹50,000');
  });
}
