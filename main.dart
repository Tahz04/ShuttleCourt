import 'package:flutter/material.dart';

class Student {
  final String imageUrl;
  final String name;
  final String studentId;
  final String position;

  Student({
    required this.imageUrl,
    required this.name,
    required this.studentId,
    required this.position,
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nhóm 6 - Đặt Sân Cầu Lông',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const StudentIntroductionPage(),
    );
  }
}

class StudentIntroductionPage extends StatelessWidget {
  const StudentIntroductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Student> students = [
      Student(
        imageUrl: 'assets/images/Mẹ.jpg',
        name: 'Dương Văn Thành',
        studentId: '20221018',
        position: 'Trưởng nhóm',
      ),
      Student(
        imageUrl: 'assets/images/Bố.jpg',
        name: 'Nguyễn Văn Duy',
        studentId: '20220995',
        position: 'Backend',
      ),
      Student(
        imageUrl: 'assets/images/shin.jpg',
        name: 'Trần T. H. Quỳnh',
        studentId: '20221008',
        position: 'Frontend',
      ),
      Student(
        imageUrl: 'assets/images/eshin.jpg',
        name: 'Nguyễn T. T. Hằng',
        studentId: '20221192',
        position: 'Frontend',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Ứng dụng đặt Sân online', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "NHÓM 6",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 1.25,
                ),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return StudentCompactCard(student: students[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentCompactCard extends StatelessWidget {
  final Student student;

  const StudentCompactCard({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(30.0),

              child: Image.asset(
                student.imageUrl,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person,
                  size: 55,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8.0),

            Text(
              student.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 2.0),

            Text(
              student.studentId,
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              student.position,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
