import 'package:flutter/material.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/features/doubt/screens/doubt_screen.dart';

class TestLoginPage extends StatelessWidget {
  const TestLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with your real JWT token and groupId
    const testToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4OGZjNTMwNWUxYTc0NGNiNmYxOWE4MCIsImVtYWlsIjoiZnJvc3R5eXVuaXZlcnNlQGdtYWlsLmNvbSIsImlhdCI6MTc1NTA3ODI4NCwiZXhwIjoxNzU1NjgzMDg0fQ.-rmNCX9Ue6eWMfcz6A_UDIaI7rvPMPDSUElZ4b10sZ4';

    const testGroupId = '688e2d4b3f51ebc203e91dd8';

    // Set the token in FrostCoreAPI for this test

    return Scaffold(
      appBar: AppBar(title: const Text('Doubts Test')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Open Doubts Screen'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoubtScreen(groupId: testGroupId),
              ),
            );
          },
        ),
      ),
    );
  }
}
