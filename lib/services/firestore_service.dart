import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

import '../models/class_schedule_model.dart';
import '../models/study_block_model.dart';
import '../models/subject_model.dart';
import '../models/task_model.dart';
import '../models/user_profile_model.dart';

class FirebaseUserBundle {
  const FirebaseUserBundle({
    required this.profile,
    required this.subjects,
    required this.classSchedules,
    required this.tasks,
    required this.studyBlocks,
    required this.wasSeeded,
  });

  final UserProfileModel profile;
  final List<SubjectModel> subjects;
  final List<ClassScheduleModel> classSchedules;
  final List<AcademicTask> tasks;
  final List<StudyBlockModel> studyBlocks;
  final bool wasSeeded;
}

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  CollectionReference<Map<String, dynamic>> _subcollection(
    String userId,
    String collection,
  ) {
    return _userDoc(userId).collection(collection);
  }

  Future<FirebaseUserBundle> loadOrSeedUserBundle(User user) async {
    final userId = user.uid;
    final profileSnapshot = await _userDoc(userId).get();

    if (!profileSnapshot.exists) {
      final seeded = _seedBundle(user);
      await saveAll(
        profile: seeded.profile,
        subjects: seeded.subjects,
        classSchedules: seeded.classSchedules,
        tasks: seeded.tasks,
        studyBlocks: seeded.studyBlocks,
      );
      return seeded;
    }

    final profile = UserProfileModel.fromFirestore(
      profileSnapshot.data() ?? const {},
      fallbackUserId: userId,
    );

    final subjects = await _readCollection<SubjectModel>(
      userId: userId,
      collection: 'subjects',
      parser: SubjectModel.fromFirestore,
    );
    final classSchedules = await _readCollection<ClassScheduleModel>(
      userId: userId,
      collection: 'classSchedules',
      parser: ClassScheduleModel.fromFirestore,
    );
    final tasks = await _readCollection<AcademicTask>(
      userId: userId,
      collection: 'tasks',
      parser: AcademicTask.fromFirestore,
    );
    final studyBlocks = await _readCollection<StudyBlockModel>(
      userId: userId,
      collection: 'studyBlocks',
      parser: StudyBlockModel.fromFirestore,
    );

    return FirebaseUserBundle(
      profile: profile,
      subjects: subjects,
      classSchedules: classSchedules,
      tasks: tasks,
      studyBlocks: studyBlocks,
      wasSeeded: false,
    );
  }

  Future<void> saveBootstrapProfile(UserProfileModel profile, {String? email}) {
    return _userDoc(profile.userId).set({
      ...profile.toFirestore(),
      'email': ?email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveAll({
    required UserProfileModel profile,
    required List<SubjectModel> subjects,
    required List<ClassScheduleModel> classSchedules,
    required List<AcademicTask> tasks,
    required List<StudyBlockModel> studyBlocks,
  }) async {
    final userId = profile.userId;

    await _replaceCollection(
      userId: userId,
      collection: 'subjects',
      items: subjects,
      idOf: (item) => item.id,
      dataOf: (item) => item.toFirestore(),
    );
    await _replaceCollection(
      userId: userId,
      collection: 'classSchedules',
      items: classSchedules,
      idOf: (item) => item.id,
      dataOf: (item) => item.toFirestore(),
    );
    await _replaceCollection(
      userId: userId,
      collection: 'tasks',
      items: tasks,
      idOf: (item) => item.id,
      dataOf: (item) => item.toFirestore(),
    );
    await _replaceCollection(
      userId: userId,
      collection: 'studyBlocks',
      items: studyBlocks,
      idOf: (item) => item.id,
      dataOf: (item) => item.toFirestore(),
    );

    await _userDoc(userId).set({
      ...profile.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSyncedAt': FieldValue.serverTimestamp(),
      'counts': {
        'subjects': subjects.length,
        'classSchedules': classSchedules.length,
        'tasks': tasks.length,
        'studyBlocks': studyBlocks.length,
      },
    }, SetOptions(merge: true));
  }

  Future<List<T>> _readCollection<T>({
    required String userId,
    required String collection,
    required T Function(String id, Map<String, dynamic> data) parser,
  }) async {
    final snapshot = await _subcollection(userId, collection).get();
    return snapshot.docs.map((doc) => parser(doc.id, doc.data())).toList();
  }

  Future<void> _replaceCollection<T>({
    required String userId,
    required String collection,
    required List<T> items,
    required String Function(T item) idOf,
    required Map<String, dynamic> Function(T item) dataOf,
  }) async {
    final ref = _subcollection(userId, collection);
    final existing = await ref.get();
    final nextIds = items.map(idOf).toSet();
    final batch = _firestore.batch();
    var hasWrites = false;

    for (final doc in existing.docs) {
      if (!nextIds.contains(doc.id)) {
        batch.delete(doc.reference);
        hasWrites = true;
      }
    }

    for (final item in items) {
      final id = idOf(item);
      batch.set(ref.doc(id), {
        ...dataOf(item),
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      hasWrites = true;
    }

    if (hasWrites) await batch.commit();
  }

  FirebaseUserBundle _seedBundle(User user) {
    final emailName = (user.email ?? 'Student').split('@').first;
    final safeName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : _titleCase(emailName.replaceAll(RegExp(r'[._-]+'), ' '));

    final nameParts = safeName.split(RegExp(r'\s+'));
    final profile = UserProfileModel(
      userId: user.uid,
      firstName: nameParts.isEmpty ? safeName : nameParts.first,
      lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      fullName: safeName,
      school: 'NU Baliwag',
      course: 'BSIT - Mobile and Web Application',
      yearLevel: '3rd Year',
      academicYear: '2025 - 2026',
      term: '3rd Term',
      preferredStudyTime: 'Evening',
      sleepStartMinute: 22 * 60,
      sleepEndMinute: 6 * 60,
      wakeMinute: 6 * 60,
      maxStudyHoursPerDay: 3,
      breakMinutes: 10,
      isWorkingStudent: false,
      hasExtracurricular: false,
    );

    return FirebaseUserBundle(
      profile: profile,
      subjects: const [],
      classSchedules: const [],
      tasks: const [],
      studyBlocks: const [],
      wasSeeded: true,
    );
  }
}

String _titleCase(String text) {
  return text
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}
