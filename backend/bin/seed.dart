import 'package:mongo_dart/mongo_dart.dart';
import 'config.dart';
import 'data/history_data.dart';
import 'data/civics_data.dart';
import 'data/geography_data.dart';
import 'data/science_data.dart';
import 'data/economy_data.dart';
import 'data/sports_data.dart';
import 'data/technology_data.dart';
import 'data/art_culture_data.dart';
import 'data/organizations_data.dart';
import 'data/environment_ecology_data.dart';

void main() async {
  print("🚀 Starting Unified Seeding Process...");

  final db = await initDatabase();

  final categoryCol = db.collection('categories');
  final topicCol = db.collection('topics');
  final questionCol = db.collection('questions');

  final Map<String, Map<String, List<Map<String, dynamic>>>> allData = {
    "History": historyData,
    "Civics": civicsData,
    "Geography": geographyData,
    "Science": scienceData,
    "Economy": economyData,
    "Sports": sportsData,
    "Technology": technologyData,
    "Art": artCultureData,
    "Organizations": organizationsData,
    "Environment": environmentData,
  };

  for (var categoryEntry in allData.entries) {
    final categoryName = categoryEntry.key;
    final topicsData = categoryEntry.value;

    print("\n📦 Seeding Category: $categoryName");

    // 1. Ensure Category Exists
    final existingCat = await categoryCol.findOne(where.eq('name', categoryName));
    if (existingCat == null) {
      await categoryCol.insertOne({'name': categoryName});
      print("  ✅ Created category '$categoryName'");
    }

    // 2. Process Topics
    for (var topicEntry in topicsData.entries) {
      final topicName = topicEntry.key;
      final questions = topicEntry.value;

      // Ensure Topic exists
      final existingTopic = await topicCol.findOne(
        where.eq('name', topicName).and(where.eq('parentCategory', categoryName))
      );

      if (existingTopic == null) {
        await topicCol.insertOne({
          'name': topicName,
          'parentCategory': categoryName,
          'createdAt': DateTime.now().toIso8601String(),
        });
        print("    📝 Created topic '$topicName'");
      }

      // 3. Clear existing questions for this topic and category to avoid duplicates
      await questionCol.deleteMany(
        where.eq('topic', topicName).and(where.eq('category', categoryName))
      );

      // 4. Insert Questions
      if (questions.isNotEmpty) {
        final List<Map<String, dynamic>> questionsToInsert = questions.map((q) {
          return {
            ...q,
            'topic': topicName,
            'category': categoryName,
          };
        }).toList();

        await questionCol.insertMany(questionsToInsert);
        print("    ✅ Seeded ${questions.length} questions for '$topicName'");
      }
    }
  }

  await db.close();
  print("\n✨ All data seeded successfully!");
}
